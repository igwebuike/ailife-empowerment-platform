import crypto from 'crypto'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { query } from './db'

const COOKIE_NAME = 'ailife_session'
const ttlMs = 1000 * 60 * 60 * 10

function secret(){ return process.env.AUTH_SECRET || process.env.JWT_SECRET || 'dev-change-me' }
function sign(payload){ return crypto.createHmac('sha256', secret()).update(payload).digest('hex') }
export function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')){
  const hash = crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256').toString('hex')
  return `${salt}:${hash}`
}
export function verifyPassword(password, stored=''){
  const [salt, hash] = stored.split(':')
  if(!salt || !hash) return false
  const check = hashPassword(password, salt).split(':')[1]
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(check))
}
export function createToken(user){
  const payload = Buffer.from(JSON.stringify({ id:user.id, email:user.email, role:user.role, name:user.full_name, exp: Date.now()+ttlMs })).toString('base64url')
  return `${payload}.${sign(payload)}`
}
export function parseToken(token){
  if(!token || !token.includes('.')) return null
  const [payload, sig] = token.split('.')
  if(sign(payload)!==sig) return null
  const data = JSON.parse(Buffer.from(payload,'base64url').toString('utf8'))
  if(Date.now() > data.exp) return null
  return data
}
export async function getCurrentUser(){
  const c = await cookies()
  return parseToken(c.get(COOKIE_NAME)?.value)
}
export async function requireUser(){
  const user = await getCurrentUser()
  if(!user) redirect('/login')
  return user
}
export async function setSession(user){
  const c = await cookies()
  c.set(COOKIE_NAME, createToken(user), { httpOnly:true, sameSite:'lax', secure:process.env.NODE_ENV==='production', path:'/', maxAge:60*60*10 })
}
export async function clearSession(){
  const c = await cookies()
  c.delete(COOKIE_NAME)
}
export async function findStaffByEmail(email){
  const res = await query('select * from staff_profiles where lower(email)=lower($1) and status=$2 limit 1',[email,'active'])
  return res.rows[0]
}
export function canManageStaff(user){
  if(!user) return false
  return ['admin','executive_director','program_director','program_manager','area_manager'].includes(user.role)
}
