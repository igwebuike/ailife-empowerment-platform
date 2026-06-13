
import { NextResponse } from 'next/server'
import { authenticator } from 'otplib'
import { findStaffByEmail, verifyPassword, setSession } from '@/lib/auth'

export async function POST(req){
  const { email, password, otp } = await req.json()
  const user = await findStaffByEmail(email || '')
  if(!user || !user.password_hash || !verifyPassword(password || '', user.password_hash)){
    return NextResponse.json({ error:'Invalid email or password' }, { status:401 })
  }
  if(process.env.ENABLE_2FA === 'true'){
    const secret = user.totp_secret || process.env.DEFAULT_TOTP_SECRET
    if(secret && !authenticator.check(String(otp||''), secret)){
      return NextResponse.json({ error:'Invalid two-factor authentication code' }, { status:401 })
    }
  }
  await setSession(user)
  return NextResponse.json({ ok:true })
}
