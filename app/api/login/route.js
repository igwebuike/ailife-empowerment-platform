import { NextResponse } from 'next/server'
import crypto from 'crypto'
import { findStaffByEmail, verifyPassword, setSession } from '@/lib/auth'
function base32ToBuffer(base32=''){const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';let bits='',bytes=[];for(const ch of String(base32).replace(/=+$/,'').replace(/\s/g,'').toUpperCase()){const val=alphabet.indexOf(ch);if(val<0)continue;bits+=val.toString(2).padStart(5,'0')}for(let i=0;i+8<=bits.length;i+=8)bytes.push(parseInt(bits.slice(i,i+8),2));return Buffer.from(bytes)}
function hotp(secret,counter){const buf=Buffer.alloc(8);buf.writeBigUInt64BE(BigInt(counter));const hmac=crypto.createHmac('sha1',base32ToBuffer(secret)).update(buf).digest();const offset=hmac[hmac.length-1]&0xf;const code=((hmac[offset]&0x7f)<<24)|(hmac[offset+1]<<16)|(hmac[offset+2]<<8)|hmac[offset+3];return String(code%1000000).padStart(6,'0')}
function verifyTotp(token,secret){if(!secret||!token)return false;const step=Math.floor(Date.now()/1000/30);return[-1,0,1].some(w=>hotp(secret,step+w)===String(token).trim())}
const portals={admin:['admin','executive_director','program_director','accountant'],investor:['board_viewer','board_trustee','governing_council','executive_director'],staff:['admin','executive_director','program_director','program_manager','area_manager','branch_manager','credit_officer','accountant','program_officer','finance_officer','compliance_officer','auditor','agent_supervisor','teller']}
export async function POST(req){
 const {email,password,otp,portal='staff'}=await req.json()
 const user=await findStaffByEmail(email||'')
 if(!user||!user.password_hash||!verifyPassword(password||'',user.password_hash)) return NextResponse.json({error:'Invalid email or password'},{status:401})
 if(portals[portal] && !portals[portal].includes(user.role)) return NextResponse.json({error:'Your role is not authorized for this portal'},{status:403})
 const required=(process.env.ENABLE_2FA==='true') || user.mfa_required
 if(required && user.totp_secret){ if(!verifyTotp(otp,user.totp_secret)) return NextResponse.json({error:'Invalid two-factor authentication code'},{status:401}) }
 await setSession(user)
 return NextResponse.json({ok:true, needs_2fa_setup: required && !user.totp_secret})
}
