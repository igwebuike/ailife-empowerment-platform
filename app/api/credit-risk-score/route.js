
import { query } from '@/lib/db'
export async function POST(req){
  try{
    const { customer_id, loan_id } = await req.json()
    if(!customer_id) return Response.json({error:'customer_id is required'}, {status:400})
    const res = await query('select calculate_internal_risk_score($1,$2) as risk_score_id',[customer_id, loan_id || null])
    return Response.json({ok:true, risk_score_id:res.rows[0].risk_score_id})
  }catch(e){ return Response.json({error:e.message}, {status:500}) }
}
