import { NextResponse } from 'next/server'
import { query } from '@/lib/db'

function scoreRisk(amount=0, income=0, hasBvn=false, hasNin=false, consent=false){
  let score = 50
  if (consent) score += 10
  if (hasBvn) score += 15
  if (hasNin) score += 10
  if (income > 0 && amount > 0) {
    const ratio = amount / income
    if (ratio <= 1.5) score += 15
    else if (ratio <= 3) score += 5
    else score -= 15
  }
  score = Math.max(0, Math.min(100, Math.round(score)))
  const risk_band = score >= 80 ? 'A - Low Risk' : score >= 65 ? 'B - Moderate Risk' : score >= 50 ? 'C - Watchlist' : 'D - High Risk'
  const decision = score >= 65 ? 'Proceed to manual credit review' : score >= 50 ? 'Escalate before approval' : 'Do not approve without senior review'
  return { score, risk_band, decision }
}

export async function POST(req){
  try {
    const body = await req.json()
    const amount = Number(body.amount || 0)
    const income = Number(body.income || 0)
    const request_type = body.request_type || 'internal_risk_report'
    const price = request_type === 'bulk_screening' ? 10000 : request_type === 'mfi_subscription' ? 25000 : 2000
    const risk = scoreRisk(amount, income, Boolean(body.bvn), Boolean(body.nin), Boolean(body.consent))
    const res = await query(
      `insert into credit_service_requests
       (request_type, customer_name, customer_phone, bvn, nin, price_amount, payment_status, status, internal_score, risk_band, decision)
       values ($1,$2,$3,$4,$5,$6,'unpaid','in_review',$7,$8,$9)
       returning request_no, internal_score, risk_band, decision, price_amount, status`,
      [request_type, body.customer_name || body.organization_name || 'Service Request', body.phone || body.customer_phone || null, body.bvn || null, body.nin || null, price, risk.score, risk.risk_band, risk.decision]
    )
    return NextResponse.json({ok:true, ...res.rows[0]})
  } catch (e) {
    return NextResponse.json({error:e.message || 'Unable to submit request'}, {status:500})
  }
}
