import { pool } from "@/lib/db";
import { NextResponse } from "next/server";

export async function POST(req) {
  try {
    const data = await req.json();

    const result = await pool.query(
      `INSERT INTO customers
      (
        full_name,
        phone,
        branch,
        loan_product,
        bvn,
        nin,
        address,
        business_type,
        requested_amount,
        income,
        loan_purpose,
        guarantor_name,
        guarantor_phone,
        guarantor_address,
        status
      )
      VALUES
      ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,'Draft')
      RETURNING id`,
      [
        data.fullName,
        data.phone,
        data.branch,
        data.loanProduct,
        data.bvn,
        data.nin,
        data.address,
        data.businessType,
        data.requestedAmount || null,
        data.income || null,
        data.loanPurpose,
        data.guarantorName,
        data.guarantorPhone,
        data.guarantorAddress
      ]
    );

    return NextResponse.json({
      success: true,
      customerId: result.rows[0].id
    });
  } catch (error) {
    console.error("Customer onboarding failed:", error);

    return NextResponse.json(
      {
        success: false,
        error: "Customer onboarding failed"
      },
      { status: 500 }
    );
  }
}