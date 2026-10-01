import crypto from 'crypto'
import { cookies } from 'next/headers'
import { redirect } from 'next/navigation'
import { query } from './db'
import { hashPassword,verifyPassword } from './auth'
const NAME='ailife_org_session',TTL=1000*60*60*8
function secret(){return process.env.AUTH_SECRET||process.env.JWT_SECRET||'dev-only-change-me'}
function sign(x){return crypto.createHmac('sha256',secret()).update(x).digest('hex')}
export async function setOrgSession(org){const c=await cookies(),p=Buffer.from(JSON.stringify({id:org.id,name:org.name,email:org.email,exp:Date.now()+TTL})).toString('base64url');c.set(NAME,`${p}.${sign(p)}`,{httpOnly:true,sameSite:'lax',secure:process.env.NODE_ENV==='production',path:'/',maxAge:60*60*8})}
export async function getOrgUser(){const c=await cookies(),v=c.get(NAME)?.value;if(!v)return null;const [p,s]=v.split('.');if(!p||sign(p)!==s)return null;try{const x=JSON.parse(Buffer.from(p,'base64url').toString());return Date.now()<x.exp?x:null}catch{return null}}
export async function requireOrg(){const o=await getOrgUser();if(!o)redirect('/group-login');return o}
export async function clearOrgSession(){const c=await cookies();c.delete(NAME)}
export async function verifyOrg(email,password){const r=(await query(`select * from organizations where lower(email)=lower($1) and status='active' limit 1`,[email])).rows[0];return r?.password_hash&&verifyPassword(password,r.password_hash)?r:null}
export {hashPassword}
