'use client'

import { Suspense, useState } from 'react'
import { useSearchParams } from 'next/navigation'

function ResetPasswordForm(){
  const searchParams = useSearchParams()
  const token = searchParams.get('token') || ''
  const [password,setPassword] = useState('')
  const [msg,setMsg] = useState('')
  const [busy,setBusy] = useState(false)

  async function go(e){
    e.preventDefault()
    if(!token){ setMsg('This reset link is invalid or missing its token.'); return }
    setBusy(true); setMsg('')
    try{
      const r=await fetch('/api/password/reset',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({token,password})})
      const j=await r.json()
      setMsg(j.ok?'Password changed. You can now sign in.':(j.error||'Password reset failed.'))
    }catch{
      setMsg('Password reset failed. Please try again.')
    }finally{ setBusy(false) }
  }

  return <main className="min-h-screen grid place-items-center bg-purple-950 p-5"><form onSubmit={go} className="card w-full max-w-md p-7"><h1 className="text-3xl font-black">Choose new password</h1><input className="input mt-5" type="password" minLength="12" value={password} onChange={e=>setPassword(e.target.value)} required placeholder="At least 12 characters"/><button disabled={busy||!token} className="btn btn-primary mt-4 w-full">{busy?'Changing password...':'Change password'}</button>{msg&&<p className="mt-4 text-sm">{msg}</p>}</form></main>
}

export default function ResetPasswordPage(){
  return <Suspense fallback={<main className="min-h-screen grid place-items-center bg-purple-950 p-5"><div className="card w-full max-w-md p-7">Loading password reset…</div></main>}><ResetPasswordForm/></Suspense>
}
