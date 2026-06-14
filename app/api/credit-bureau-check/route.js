
import { query } from '@/lib/db'
export async function POST(req){
  try{
    const { customer_id, loan_id, provider_code='CREDIT_REGISTRY' } = await req.json()
    if(!customer_id) return Response.json({error:'customer_id is required'}, {status:400})
    const prov = await query('select id, enabled, live_checks_allowed from credit_bureau_providers where provider_code=$1',[provider_code])
    if(!prov.rows[0]) return Response.json({error:'provider not configured'}, {status:404})
    const status = (prov.rows[0].enabled && prov.rows[0].live_checks_allowed) ? 'pending' : 'not_configured'
    const notes = status==='not_configured' ? 'Credit bureau credentials not active yet; use internal risk score and manual review.' : null
    const res = await query(`insert into credit_bureau_checks(customer_id,loan_id,provider_id,check_type,status,error_message,request_payload)
      values($1,$2,$3,'credit_report',$4,$5,jsonb_build_object('provider_code',$6,'mode','credential_ready_placeholder')) returning id`,
      [customer_id, loan_id || null, prov.rows[0].id, status, notes, provider_code])
    return Response.json({ok:true, credit_bureau_check_id:res.rows[0].id, status, message:notes})
  }catch(e){ return Response.json({error:e.message}, {status:500}) }
}
