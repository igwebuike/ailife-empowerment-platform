import { NextResponse } from 'next/server'
import { query } from '@/lib/db'
import { getCurrentUser, canManageStaff, hashPassword } from '@/lib/auth'

export async function GET(){
  const user = await getCurrentUser()
  if(!user) return NextResponse.json({ error:'Unauthorized' }, { status:401 })

  let sql = `
    select sp.id, sp.full_name, sp.email, sp.phone, sp.department, sp.role,
           coalesce(b.name, sp.branch) as branch, sp.area, sp.approval_limit,
           sp.can_view_all_branches, sp.mfa_required, sp.status, sp.created_at
    from staff_profiles sp
    left join branches b on b.id = sp.branch_id
  `
  const params = []

  if(!user.can_view_all_branches && user.role !== 'executive_director'){
    sql += ` where (sp.branch_id::text = $1 or sp.branch = $2 or sp.area = $3)`
    params.push(user.branch_id || '', user.branch || '', user.area || '')
  }

  sql += ` order by sp.created_at desc limit 200`
  const res = await query(sql, params)
  return NextResponse.json({ staff: res.rows })
}

export async function POST(req){
  const currentUser = await getCurrentUser()
  const count = await query('select count(*)::int as count from staff_profiles')
  const isBootstrap = count.rows[0].count === 0

  if(!isBootstrap && !canManageStaff(currentUser)){
    return NextResponse.json({ error:'Only authorized leadership can create staff profiles' }, { status:403 })
  }

  const data = await req.json()
  const password = data.password || 'ChangeMe@12345'
  const passwordHash = hashPassword(password)

  let branchId = data.branchId || null
  if(!branchId && data.branch){
    const b = await query('select id from branches where name=$1 limit 1', [data.branch])
    branchId = b.rows[0]?.id || null
  }

  const result = await query(`
    insert into staff_profiles
    (full_name,email,phone,department,role,branch_id,branch,area,approval_limit,can_view_all_branches,mfa_required,password_hash,status)
    values ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,'active')
    returning id, full_name, email, role
  `, [
    data.fullName,
    data.email,
    data.phone || null,
    data.department || 'Operations',
    data.role,
    branchId,
    data.branch || null,
    data.area || null,
    Number(data.approvalLimit || 0),
    Boolean(data.canViewAllBranches),
    Boolean(data.mfaRequired ?? true),
    passwordHash
  ])

  return NextResponse.json({ success:true, staff: result.rows[0], temporaryPassword: password, bootstrap: isBootstrap })
}
