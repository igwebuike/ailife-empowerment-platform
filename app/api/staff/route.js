import crypto from 'crypto'
import { NextResponse } from 'next/server'
import { query } from '@/lib/db'
import { getCurrentUser, canManageStaff, hashPassword } from '@/lib/auth'

const editableRoles=['admin','executive_director','program_director','program_manager','area_manager','branch_manager','credit_officer','accountant','program_officer','finance_officer','compliance_officer','auditor','agent_supervisor','teller','secretary','receptionist']
const normalize=s=>String(s||'').trim().toLowerCase()
function tempPassword(){return `Aible!${crypto.randomBytes(8).toString('base64url')}9a`}
function mayEdit(actor,targetRole,newRole){
 if(actor?.role==='super_admin') return newRole!=='super_admin'
 if(actor?.role==='admin') return !['super_admin','admin'].includes(targetRole) && !['super_admin','admin'].includes(newRole)
 return false
}
export async function GET(){
 const user=await getCurrentUser(); if(!user) return NextResponse.json({error:'Unauthorized'},{status:401})
 let sql=`select sp.id,sp.full_name,sp.email,sp.phone,sp.department,sp.role,sp.branch_id,coalesce(b.name,sp.branch) branch,sp.area,sp.approval_limit,sp.can_view_all_branches,sp.mfa_required,sp.force_password_change,sp.status,sp.created_at from staff_profiles sp left join branches b on b.id=sp.branch_id`
 const params=[]; if(!user.can_view_all_branches && !['super_admin','executive_director'].includes(user.role)){sql+=` where (sp.branch_id::text=$1 or sp.branch=$2 or sp.area=$3)`;params.push(user.branch_id||'',user.branch||'',user.area||'')}
 sql+=` order by sp.created_at desc limit 200`; return NextResponse.json({staff:(await query(sql,params)).rows,can_manage:['super_admin','admin'].includes(user.role),is_super_admin:user.role==='super_admin'})
}
export async function POST(req){
 const actor=await getCurrentUser(); const count=await query('select count(*)::int count from staff_profiles'); const bootstrap=count.rows[0].count===0
 if(!bootstrap && !['super_admin','admin'].includes(actor?.role)) return NextResponse.json({error:'Only Super Admin or Admin can create staff.'},{status:403})
 const d=await req.json(); const role=normalize(d.role); if(!editableRoles.includes(role)) return NextResponse.json({error:'Invalid role.'},{status:400}); if(actor?.role!=='super_admin'&&role==='admin') return NextResponse.json({error:'Only Super Admin can create an Admin.'},{status:403})
 const exists=await query('select id from staff_profiles where lower(email)=lower($1) limit 1',[d.email]); if(exists.rows[0]) return NextResponse.json({error:'A staff profile already exists for this email. Edit the existing account instead.'},{status:409})
 const password=tempPassword(); const r=await query(`insert into staff_profiles(full_name,email,phone,department,role,branch_id,branch,area,approval_limit,can_view_all_branches,mfa_required,password_hash,force_password_change,status) values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,true,'Active') returning id,full_name,email,role`,[d.fullName,d.email,d.phone||null,d.department||'Operations',role,d.branchId||null,d.branch||null,d.area||null,Number(d.approvalLimit||0),Boolean(d.canViewAllBranches),Boolean(d.mfaRequired??true),hashPassword(password)])
 return NextResponse.json({success:true,staff:r.rows[0],temporaryPassword:password})
}
export async function PATCH(req){
 const actor=await getCurrentUser(); if(!['super_admin','admin'].includes(actor?.role)) return NextResponse.json({error:'Only Super Admin or Admin can manage staff accounts.'},{status:403})
 const d=await req.json(); const target=(await query('select * from staff_profiles where id=$1',[d.id])).rows[0]; if(!target) return NextResponse.json({error:'Staff account not found.'},{status:404})
 const role=normalize(d.role||target.role); if(!editableRoles.includes(role)&&role!=='super_admin') return NextResponse.json({error:'Invalid role.'},{status:400}); if(!mayEdit(actor,normalize(target.role),role)) return NextResponse.json({error:'You cannot modify this privileged account.'},{status:403})
 let branchId=d.branchId??target.branch_id; if(!branchId&&d.branch){const b=await query('select id from branches where name=$1 limit 1',[d.branch]);branchId=b.rows[0]?.id||null}
 await query(`update staff_profiles set full_name=$1,phone=$2,department=$3,role=$4,branch_id=$5,branch=$6,area=$7,approval_limit=$8,can_view_all_branches=$9,mfa_required=$10,status=$11 where id=$12`,[d.fullName||target.full_name,d.phone??target.phone,d.department||target.department,role,branchId,d.branch??target.branch,d.area??target.area,Number(d.approvalLimit??target.approval_limit??0),Boolean(d.canViewAllBranches??target.can_view_all_branches),Boolean(d.mfaRequired??target.mfa_required),d.status||target.status,d.id])
 let temporaryPassword=null; if(d.activateLogin||d.resetPassword){temporaryPassword=tempPassword();await query('update staff_profiles set password_hash=$1,force_password_change=true where id=$2',[hashPassword(temporaryPassword),d.id])}
 if(d.resetMfa) await query('update staff_profiles set totp_secret=null where id=$1',[d.id])
 return NextResponse.json({success:true,temporaryPassword})
}
