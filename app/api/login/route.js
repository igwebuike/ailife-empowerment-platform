import { NextResponse } from 'next/server'
import crypto from 'crypto'
import { findStaffByEmail, verifyPassword, setSession } from '@/lib/auth'

function base32ToBuffer(base32=''){
  const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
  let bits='', bytes=[]
  for(const ch of String(base32).replace(/=+$/,'').replace(/\s/g,'').toUpperCase()){
    const val=alphabet.indexOf(ch); if(val<0) continue
    bits += val.toString(2).padStart(5,'0')
  }
  for(let i=0;i+8<=bits.length;i+=8) bytes.push(parseInt(bits.slice(i,i+8),2))
  return Buffer.from(bytes)
}
function hotp(secret, counter){
  const buf=Buffer.alloc(8); buf.writeBigUInt64BE(BigInt(counter))
  const hmac=crypto.createHmac('sha1', base32ToBuffer(secret)).update(buf).digest()
  const offset=hmac[hmac.length-1]&0xf
  const code=((hmac[offset]&0x7f)<<24)|(hmac[offset+1]<<16)|(hmac[offset+2]<<8)|hmac[offset+3]
  return String(code % 1000000).padStart(6,'0')
}
function verifyTotp(token, secret){
  if(!secret || !token) return false
  const step=Math.floor(Date.now()/1000/30)
  return [-1,0,1].some(w => hotp(secret, step+w) === String(token))
}

export async function POST(req){
  const { email, password, otp } = await req.json()
  const user = await findStaffByEmail(email || '')
  if(!user || !user.password_hash || !verifyPassword(password || '', user.password_hash)){
    return NextResponse.json({ error:'Invalid email or password' }, { status:401 })
  }
  if(process.env.ENABLE_2FA === 'true'){
    const secret = user.totp_secret || process.env.DEFAULT_TOTP_SECRET
    const fallbackCode = process.env.DEFAULT_TOTP_CODE
    const ok = secret ? verifyTotp(String(otp||''), secret) : (fallbackCode && String(otp||'') === fallbackCode)
    if(!ok) return NextResponse.json({ error:'Invalid two-factor authentication code' }, { status:401 })
  }
  await setSession(user)
  return NextResponse.json({ ok:true })
}
