import { pool } from '@/lib/db'
import { NextResponse } from 'next/server'

function cleanNumber(v){ return v ? Number(String(v).replace(/[^0-9.]/g, '')) : null }

export async function POST(req) {
  try {
    const data = await req.json()
    const result = await pool.query(
      `INSERT INTO customers
      (full_name, phone, branch, loan_product, savings_product, repayment_method, bvn, nin, address, business_type, requested_amount, income, loan_purpose, guarantor_name, guarantor_phone, guarantor_address, consent_credit_check, consent_data_sharing, status)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,true,true,'Draft')
      RETURNING id`,
      [data.fullName, data.phone, data.branch, data.loanProduct, data.savingsProduct, data.repaymentMethod, data.bvn, data.nin, data.address, data.businessType, cleanNumber(data.requestedAmount), cleanNumber(data.income), data.loanPurpose, data.guarantorName, data.guarantorPhone, data.guarantorAddress]
    )
    await pool.query(`update customers set customer_no = coalesce(customer_no, 'CUS-' || lpad(id::text, 6, '0')) where id=$1`, [result.rows[0].id])
    return NextResponse.json({ success: true, customerId: result.rows[0].id })
  } catch (error) {
    console.error('Customer onboarding failed:', error)
    return NextResponse.json({ success: false, error: error.message || 'Customer onboarding failed' }, { status: 500 })
  }
}
