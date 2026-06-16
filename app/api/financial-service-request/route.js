import { NextResponse } from 'next/server'
export async function POST(req){
  const body=await req.json().catch(()=>({}))
  const request_no='AFS-'+Date.now().toString().slice(-8)
  const status=['sme_cross_border','pos_network'].includes(body.type)?'compliance_review':'received'
  return NextResponse.json({ok:true,request_no,status,message:'Financial service request captured for operations/compliance review. Live regulated processing requires approved provider credentials.'})
}
