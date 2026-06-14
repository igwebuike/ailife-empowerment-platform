import { Pool } from 'pg'

const connectionString = process.env.DATABASE_URL
const hasDb = Boolean(connectionString)
if (!hasDb && process.env.NODE_ENV !== 'development') {
  console.warn('DATABASE_URL is not set. Build will use empty dashboard data. Add Render PostgreSQL Internal Database URL at runtime.')
}

const globalForPg = globalThis
export const pool = hasDb
  ? (globalForPg.__ailifePool || new Pool({
      connectionString,
      ssl: process.env.PGSSLMODE === 'require' ? { rejectUnauthorized: false } : false,
      allowExitOnIdle: true,
    }))
  : null
if (hasDb && process.env.NODE_ENV !== 'production') globalForPg.__ailifePool = pool

const baseTables = [
  'customers','loans','transactions','risk_alerts','staff_profiles','ledger_entries','approval_workflows','branch_cash_accounts','agents','kyc_documents','beneficiaries','programs','tasks','branches','loan_products','loan_approval_rules','organizational_units','staff_onboarding_cases','training_modules','staff_training_records','client_onboarding_cases','onboarding_checklist_items','onboarding_checklist_progress','notification_outbox','credit_bureau_providers','credit_bureau_checks','internal_risk_rules','internal_risk_scores','manual_credit_reviews','credit_bureau_audit_events','service_clients','customer_consents','credit_service_products','credit_service_requests','credit_check_orders','bureau_upload_queue','saas_subscriptions','api_clients','revenue_events'
]
const allowedRows = new Set(baseTables)
const allowedCounts = new Set(baseTables)

export async function query(text, params = []) {
  if (!pool) throw new Error('DATABASE_URL is not configured')
  return await pool.query(text, params)
}

export async function rows(table, limit = 100) {
  if (!allowedRows.has(table)) throw new Error(`Blocked unsafe table: ${table}`)
  if (!pool) return []
  const { rows } = await query(`select * from ${table} order by created_at desc limit $1`, [limit])
  return rows
}

export async function countRows(table) {
  if (!allowedCounts.has(table)) throw new Error(`Blocked unsafe table: ${table}`)
  if (!pool) return 0
  const res = await query(`select count(*)::int as count from ${table}`)
  return res.rows[0]?.count || 0
}

export async function sumWhere(table, col, whereCol, whereVal, extraCol, extraVal) {
  const allowed = new Set(['transactions'])
  if (!allowed.has(table)) throw new Error(`Blocked unsafe table: ${table}`)
  if (!pool) return 0
  let sql = `select coalesce(sum(${col}),0)::numeric as total from ${table} where ${whereCol}=$1`
  const params = [whereVal]
  if (extraCol) { sql += ` and ${extraCol}=$2`; params.push(extraVal) }
  const res = await query(sql, params)
  return Number(res.rows[0]?.total || 0)
}
