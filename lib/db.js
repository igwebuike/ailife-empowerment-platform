import { Pool } from 'pg'

const connectionString = process.env.DATABASE_URL
const hasDb = Boolean(connectionString)
if (!hasDb && process.env.NODE_ENV !== 'development') {
  console.warn('DATABASE_URL is not set. Add Render PostgreSQL Internal Database URL at runtime.')
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
  'approval_workflows','audit_logs','branches','chart_of_accounts','credit_bureau_requests',
  'customers','documents','fraud_alerts','guarantors','kyc_documents','ledger_entries',
  'ledger_journals','loan_applications','loan_products','loans','notifications',
  'organization_settings','repayment_methods','repayment_schedules','repayments',
  'role_permissions','savings_accounts','savings_products','staff','staff_branch_access',
  'staff_profiles','transactions'
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
  const { rows } = await query(`select * from ${table} order by id desc limit $1`, [limit])
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
