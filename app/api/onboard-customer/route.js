import { NextResponse } from 'next/server'
import { query } from '@/lib/db'

function cleanNumber(v){ return v ? Number(String(v).replace(/[^0-9.]/g, '')) : null }

export async function POST(req){
 try{
  const b = await req.json()
  if(!b.full_name || !b.phone) return NextResponse.json({error:'Full name and phone are required'}, {status:400})
  const br = await query('select id from branches where name=$1 limit 1',[b.branch||'Head Office'])
  const branchId = br.rows[0]?.id || null
  const customer = await query(`
    insert into customers
    (full_name, phone, branch, branch_id, loan_product, bvn, nin, address, business_type, requested_amount, income, loan_purpose, guarantor_name, guarantor_phone, guarantor_address, consent_credit_check, consent_data_sharing, status)
    values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,true,true,'pending_kyc')
    returning id
  `,[b.full_name,b.phone,b.branch||'Head Office',branchId,b.loan_product||'Daily Loan',b.bvn||null,b.nin||null,b.address||null,b.business_type||null,cleanNumber(b.requested_amount),cleanNumber(b.income),b.loan_purpose||null,b.guarantor_name||null,b.guarantor_phone||null,b.guarantor_address||null])
  const c = customer.rows[0]
  await query(`update customers set customer_no = coalesce(customer_no, 'CUS-' || lpad(id::text, 6, '0')) where id=$1`, [c.id])

  if(b.guarantor_name){
    await query(`insert into guarantors(customer_id, full_name, phone, address) values($1,$2,$3,$4)`, [c.id,b.guarantor_name,b.guarantor_phone||null,b.guarantor_address||null])
  }

  if(b.requested_amount){
    const product = await query('select id from loan_products where lower(name)=lower($1) limit 1',[b.loan_product||'Daily Loan'])
    await query(`insert into loan_applications(customer_id, branch_id, loan_product_id, requested_amount, loan_purpose, application_status, credit_bureau_status, submitted_at)
      values($1,$2,$3,$4,$5,'submitted','pending',now())`, [c.id, branchId, product.rows[0]?.id || null, cleanNumber(b.requested_amount), b.loan_purpose || null])
  }

  await query(`insert into audit_logs(action, entity_type, entity_id, new_value) values('customer_onboarding_submitted','customers',$1,$2)`, [c.id, b])
  return NextResponse.json({ok:true, customer_no:`CUS-${String(c.id).padStart(6,'0')}`, customer_id:c.id})
 }catch(e){
  console.error(e)
  return NextResponse.json({error:e.message},{status:500})
 }
}
