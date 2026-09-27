import { NextResponse } from 'next/server'
import { query, pool } from '@/lib/db'
import { getCurrentUser } from '@/lib/auth'

const DATASETS = {
  customers: { table:'customers', columns:['id','full_name','phone','email','status','branch_id','created_at'], roles:null },
  loans: { table:'loans', columns:['id','customer_id','customer_name','principal','outstanding_balance','status','branch_id','created_at'], roles:null },
  transactions: { table:'transactions', columns:['id','customer_id','loan_id','branch_id','reference','type','transaction_type','amount','channel','status','created_at'], roles:null },
  contributions: { table:'contributions', columns:['id','organization_id','member_id','plan_id','amount','due_date','paid_at','channel','provider_reference','status','created_at'], roles:null },
  credit_events: { table:'credit_events', columns:['id','customer_id','event_type','source_type','source_id','amount','status','occurred_at','created_at'], roles:null },
  decision_runs: { table:'decision_runs', columns:['id','customer_id','loan_id','score','risk_band','decision','route_role','created_at'], roles:null },
  staff_profiles: { table:'staff_profiles', columns:['id','full_name','email','role','branch_id','status','created_at'], roles:['admin','executive_director','program_director','program_manager','area_manager'] }
}
const OPS_ROLES = new Set(['admin','executive_director','program_director','program_manager','area_manager','branch_manager','credit_officer','accountant','finance_officer','teller'])
const ADMIN_ROLES = new Set(['admin','executive_director','program_director'])
const safeKey = v => /^[a-z_][a-z0-9_]*$/i.test(v||'')

async function existingColumns(table, requested){
  const r=await query(`select column_name from information_schema.columns where table_schema='public' and table_name=$1`,[table])
  const have=new Set(r.rows.map(x=>x.column_name)); return requested.filter(c=>have.has(c))
}
function branchScope(user, cols, params, clauses){
  if(!user.can_view_all_branches && user.branch_id && cols.includes('branch_id')){ params.push(user.branch_id); clauses.push(`branch_id=$${params.length}`) }
}
async function audit(user,operation,dataset,filters,affected,summary={}){
  await query(`insert into workbench_runs(actor_id,operation,dataset,filters,affected_rows,result_summary) values($1,$2,$3,$4,$5,$6)`,[user.id,operation,dataset,JSON.stringify(filters||{}),affected,JSON.stringify(summary)])
  try{ await query(`insert into audit_events(actor_id,action,entity_type,metadata) values($1,$2,$3,$4)`,[user.id,`workbench.${operation}`,dataset,JSON.stringify({filters,affected,...summary})]) }catch{}
}
export async function GET(req){
 const u=await getCurrentUser(); if(!u)return NextResponse.json({error:'Unauthorized'},{status:401})
 const url=new URL(req.url), key=url.searchParams.get('dataset')||'customers', cfg=DATASETS[key]
 if(!cfg || (cfg.roles && !cfg.roles.includes(u.role)))return NextResponse.json({error:'Dataset not permitted'},{status:403})
 const cols=await existingColumns(cfg.table,cfg.columns); if(!cols.length)return NextResponse.json({error:'Dataset unavailable'},{status:404})
 const params=[], clauses=[]; branchScope(u,cols,params,clauses)
 for(const name of ['status','customer_id','branch_id','type','transaction_type','event_type']){
   const val=url.searchParams.get(name); if(val && cols.includes(name) && safeKey(name)){params.push(val);clauses.push(`${name}=$${params.length}`)}
 }
 const search=url.searchParams.get('search'); const searchable=['full_name','customer_name','phone','email','reference'].filter(c=>cols.includes(c))
 if(search && searchable.length){params.push(`%${search}%`); clauses.push(`(${searchable.map(c=>`${c}::text ilike $${params.length}`).join(' or ')})`)}
 params.push(Math.min(Number(url.searchParams.get('limit')||50),200))
 const order=cols.includes('created_at')?'created_at desc':cols.includes('id')?'id desc':cols[0]
 const sql=`select ${cols.join(',')} from ${cfg.table}${clauses.length?' where '+clauses.join(' and '):''} order by ${order} limit $${params.length}`
 const r=await query(sql,params); return NextResponse.json({dataset:key,columns:cols,rows:r.rows})
}
export async function POST(req){
 const u=await getCurrentUser(); if(!u)return NextResponse.json({error:'Unauthorized'},{status:401})
 if(!OPS_ROLES.has(u.role))return NextResponse.json({error:'Your role cannot run workbench transactions'},{status:403})
 const body=await req.json(), action=String(body.action||'')
 if(action==='record_transaction'){
   const amount=Number(body.amount); if(!body.customer_id || !Number.isFinite(amount) || amount<=0)return NextResponse.json({error:'Customer and positive amount are required'},{status:400})
   const allowedTypes=new Set(['deposit','withdrawal','loan_repayment','fee','adjustment']); const type=String(body.type||'deposit'); if(!allowedTypes.has(type))return NextResponse.json({error:'Unsupported transaction type'},{status:400})
   const allowedChannels=new Set(['cash','bank_transfer','pos','mobile_money','ussd','agent','manual']); const channel=allowedChannels.has(body.channel)?body.channel:'cash'
   const client=await pool.connect(); try{
    await client.query('BEGIN')
    const cr=await client.query('select id,full_name,branch_id from customers where id=$1 for share',[body.customer_id]); if(!cr.rows[0])throw new Error('Customer not found')
    const c=cr.rows[0]; if(!u.can_view_all_branches && u.branch_id && c.branch_id && Number(c.branch_id)!==Number(u.branch_id))throw new Error('Customer is outside your branch scope')
    const ic=await client.query(`select column_name from information_schema.columns where table_schema='public' and table_name='transactions'`); const have=new Set(ic.rows.map(x=>x.column_name))
    const names=[],vals=[],ph=[]; const add=(n,v)=>{if(have.has(n)){names.push(n);vals.push(v);ph.push(`$${vals.length}`)}}
    add('customer_id',c.id); add('customer_name',c.full_name); add('loan_id',body.loan_id||null); add('branch_id',c.branch_id||u.branch_id||null); add('type',type); add('transaction_type',type); add('amount',amount); add('channel',channel); add('status','pending'); add('maker_id',u.id); add('created_by',u.id); add('description',body.description||`Workbench ${type}`)
    if(!have.has('amount') || (!have.has('type')&&!have.has('transaction_type')))throw new Error('Production transaction schema is not compatible with controlled posting')
    const tr=await client.query(`insert into transactions(${names.join(',')}) values(${ph.join(',')}) returning *`,vals)
    await client.query('COMMIT'); await audit(u,action,'transactions',{customer_id:c.id,type,channel},1,{transaction_id:tr.rows[0].id,status:tr.rows[0].status||'pending'})
    return NextResponse.json({ok:true,message:'Transaction created and routed as pending for normal approval controls.',row:tr.rows[0]})
   }catch(e){await client.query('ROLLBACK');return NextResponse.json({error:e.message},{status:400})}finally{client.release()}
 }
 if(action==='update_status'){
   if(!ADMIN_ROLES.has(u.role))return NextResponse.json({error:'Status correction requires senior authorization'},{status:403})
   const key=String(body.dataset||''), cfg=DATASETS[key]; if(!cfg || !['customers','loans','contributions'].includes(key))return NextResponse.json({error:'Status update not permitted for this dataset'},{status:400})
   const allowed=new Set(['active','inactive','verified','suspended','pending','approved','rejected','paid','overdue','missed','closed','defaulted']); if(!allowed.has(String(body.status)))return NextResponse.json({error:'Status value is not permitted'},{status:400})
   const cols=await existingColumns(cfg.table,['id','status','branch_id']); if(!cols.includes('status'))return NextResponse.json({error:'Dataset has no status field'},{status:400})
   const params=[body.status,body.id], scope=[]; if(!u.can_view_all_branches&&u.branch_id&&cols.includes('branch_id')){params.push(u.branch_id);scope.push(`branch_id=$3`)}
   const r=await query(`update ${cfg.table} set status=$1 where id=$2${scope.length?' and '+scope.join(' and '):''} returning id,status`,params); await audit(u,action,key,{id:body.id,status:body.status},r.rowCount)
   return NextResponse.json({ok:true,affected:r.rowCount,row:r.rows[0]||null})
 }
 return NextResponse.json({error:'Unsupported workbench operation'},{status:400})
}
