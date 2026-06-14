
import { Pool } from 'pg'

const connectionString = process.env.DATABASE_URL
if (!connectionString && process.env.NODE_ENV !== 'development') {
  console.warn('DATABASE_URL is not set. Add Render PostgreSQL Internal Database URL.')
}

const globalForPg = globalThis
export const pool = globalForPg.__ailifePool || new Pool({
  connectionString,
  ssl: process.env.PGSSLMODE === 'require' ? { rejectUnauthorized: false } : false,
})
if (process.env.NODE_ENV !== 'production') globalForPg.__ailifePool = pool

export async function query(text, params = []) {
  const res = await pool.query(text, params)
  return res
}

export async function rows(table, limit = 100) {
  const allowed = new Set(['customers','loans','transactions','risk_alerts','staff_profiles','ledger_entries','approval_workflows','branch_cash_accounts','agents','kyc_documents','beneficiaries','programs','tasks','branches','loan_products','loan_approval_rules','organizational_units','staff_onboarding_cases','training_modules','staff_training_records','client_onboarding_cases','onboarding_checklist_items','onboarding_checklist_progress','notification_outbox','credit_bureau_providers','credit_bureau_checks','internal_risk_rules','internal_risk_scores','manual_credit_reviews','credit_bureau_audit_events'])
  if (!allowed.has(table)) throw new Error(`Blocked unsafe table: ${table}`)
  const { rows } = await query(`select * from ${table} order by created_at desc limit $1`, [limit])
  return rows
}

export async function countRows(table) {
  const allowed = new Set(['customers','loans','transactions','risk_alerts','ledger_entries','approval_workflows','branch_cash_accounts','agents','staff_profiles','branches','loan_products','staff_onboarding_cases','training_modules','client_onboarding_cases','credit_bureau_providers','credit_bureau_checks','internal_risk_scores','manual_credit_reviews'])
  if (!allowed.has(table)) throw new Error(`Blocked unsafe table: ${table}`)
  const res = await query(`select count(*)::int as count from ${table}`)
  return res.rows[0]?.count || 0
}

export async function sumWhere(table, col, whereCol, whereVal, extraCol, extraVal) {
  const allowed = new Set(['transactions'])
  if (!allowed.has(table)) throw new Error(`Blocked unsafe table: ${table}`)
  let sql = `select coalesce(sum(${col}),0)::numeric as total from ${table} where ${whereCol}=$1`
  const params = [whereVal]
  if (extraCol) { sql += ` and ${extraCol}=$2`; params.push(extraVal) }
  const res = await query(sql, params)
  return Number(res.rows[0]?.total || 0)
}
