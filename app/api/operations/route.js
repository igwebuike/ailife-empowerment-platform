import { NextResponse } from 'next/server'
import { query } from '@/lib/db'
import { getCurrentUser } from '@/lib/auth'
export async function POST(req){
 const u=await getCurrentUser(); if(!u)return NextResponse.json({error:'Unauthorized'},{status:401})
 const f=await req.formData(), action=String(f.get('action')||''); let result
 if(action==='client_onboarding') result=await query(`insert into client_onboarding_cases(customer_id,full_name,phone,branch_id,onboarding_channel,status,assigned_staff_id) values($1,$2,$3,$4,$5,'started',$6) returning id`,[f.get('customer_id')||null,f.get('full_name'),f.get('phone'),f.get('branch_id')||null,f.get('channel')||'branch',f.get('assigned_staff_id')||u.id])
 else if(action==='staff_onboarding') result=await query(`insert into staff_onboarding_cases(staff_id,full_name,role,branch_id,email,phone,status,start_date,created_by) values($1,$2,$3,$4,$5,$6,'pending',$7,$8) returning id`,[f.get('staff_id')||null,f.get('full_name'),f.get('role'),f.get('branch_id')||null,f.get('email')||null,f.get('phone')||null,f.get('start_date')||null,u.id])
 else if(action==='service_client') result=await query(`insert into service_clients(organization_name,client_type,contact_name,email,phone,status,plan_code) values($1,$2,$3,$4,$5,'lead',$6) returning id`,[f.get('organization_name'),f.get('client_type')||'microfinance',f.get('contact_name')||null,f.get('email')||null,f.get('phone')||null,f.get('plan_code')||'starter'])
 else if(action==='consent') result=await query(`insert into customer_consents(service_client_id,customer_id,customer_name,phone,consent_type,consent_channel,consent_text,signed_at,status) values($1,$2,$3,$4,$5,$6,$7,now(),'active') returning id`,[f.get('service_client_id')||null,f.get('customer_id')||null,f.get('customer_name'),f.get('phone')||null,f.get('consent_type')||'credit_check',f.get('consent_channel')||'digital',f.get('consent_text')||'Customer consent captured by authorized staff.'])
 else return NextResponse.json({error:'Unsupported operation'},{status:400})
 await query(`insert into audit_events(actor_id,action,entity_type,entity_id,metadata) values($1,$2,$3,$4,$5)`,[u.id,`operation.${action}`,action,String(result.rows[0].id),JSON.stringify({source:'operations_center'})])
 return NextResponse.redirect(new URL('/dashboard/operations?saved=1',req.url),303)
}
