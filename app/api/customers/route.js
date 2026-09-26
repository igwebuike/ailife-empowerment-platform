import { NextResponse } from 'next/server'
import { query } from '@/lib/db'
import { requireUser } from '@/lib/auth'

export async function POST(req) {
  try {
    const user = await requireUser()
    const data = await req.json()
    const fullName = data.fullName || data.full_name
    const phone = data.phone
    if (!fullName || !phone) return NextResponse.json({ success:false, error:'Full name and phone are required' }, { status:400 })

    const branchName = data.branch || 'Head Office'
    const br = await query('select id from branches where name=$1 limit 1', [branchName])
    const branchId = br.rows[0]?.id || null
    const result = await query(
      `insert into customers(full_name,phone,email,bvn,nin,address,business_name,community,branch_id,branch,status,created_by)
       values($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'pending_kyc',$11)
       returning id,customer_no`,
      [fullName,phone,data.email||null,data.bvn||null,data.nin||null,data.address||null,data.businessType||data.business_type||null,data.community||null,branchId,branchName,user.id]
    )
    return NextResponse.json({ success:true, customerId:result.rows[0].id, customer_no:result.rows[0].customer_no })
  } catch (error) {
    console.error('Customer onboarding failed:', error)
    return NextResponse.json({ success:false, error:'Customer onboarding failed' }, { status:500 })
  }
}
