import crypto from 'crypto'
import { NextResponse } from 'next/server'
import { pool } from '@/lib/db'
import { hashPassword } from '@/lib/auth'

export async function POST(req){
  const {token,password}=await req.json()
  if(!token||!password||password.length<12) return NextResponse.json({error:'Use a password of at least 12 characters.'},{status:400})
  if(!pool) return NextResponse.json({error:'Database is not configured.'},{status:503})
  const h=crypto.createHash('sha256').update(token).digest('hex')
  const client=await pool.connect()
  try{
    await client.query('begin')
    const r=await client.query(`select * from password_reset_tokens where token_hash=$1 and used_at is null and expires_at>now() order by created_at desc limit 1 for update`,[h])
    if(!r.rows[0]){await client.query('rollback'); return NextResponse.json({error:'Reset link is invalid or expired.'},{status:400})}
    await client.query('update staff_profiles set password_hash=$1 where id=$2',[hashPassword(password),r.rows[0].staff_id])
    await client.query('update password_reset_tokens set used_at=now() where staff_id=$1 and used_at is null',[r.rows[0].staff_id])
    await client.query('commit')
    return NextResponse.json({ok:true})
  }catch(e){await client.query('rollback'); console.error('Password reset failed:',e); return NextResponse.json({error:'Password reset failed.'},{status:500})}
  finally{client.release()}
}
