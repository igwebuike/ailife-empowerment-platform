import { NextResponse } from 'next/server'
import { query } from '@/lib/db'
export async function POST(req){
 try{
  const b=await req.json(); if(!b.full_name || !b.phone) return NextResponse.json({error:'Full name and phone are required'}, {status:400})
  const br=await query('select id from branches where name=$1 limit 1',[b.branch||'Head Office']); const branchId=br.rows[0]?.id || null
  const customer=await query(`insert into customers(full_name,phone,bvn,nin,address,business_name,community,branch_id,branch,status) values($1,$2,$3,$4,$5,$6,$7,$8,$9,'pending_kyc') returning id,customer_no`,[b.full_name,b.phone,b.bvn||null,b.nin||null,b.address||null,b.business_type||null,b.loan_purpose||null,branchId,b.branch||'Head Office'])
  const c=customer.rows[0]
  if(b.requested_amount){ await query(`insert into loans(customer_id,customer_name,principal,outstanding_balance,interest_rate,status,created_at) values($1,$2,$3,0,$4,'submitted',now())`,[c.id,b.full_name,Number(b.requested_amount||0), b.loan_product==='Monthly Loan'?10:20]) }
  await query(`insert into audit_logs(action,entity_table,entity_id,after_data) values('customer_onboarding_submitted','customers',$1,$2)`,[c.id, JSON.stringify(b)])
  return NextResponse.json({ok:true, customer_no:c.customer_no})
 }catch(e){return NextResponse.json({error:e.message},{status:500})}
}
