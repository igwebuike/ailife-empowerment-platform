'use client'
import { useState } from 'react'

export default function PasswordInput({ className='input', value, onChange, ...props }){
  const [visible,setVisible]=useState(false)
  return <div className="relative">
    <input {...props} className={`${className} pr-12`} type={visible?'text':'password'} value={value} onChange={onChange}/>
    <button type="button" onClick={()=>setVisible(v=>!v)} aria-label={visible?'Hide password':'Show password'} title={visible?'Hide password':'Show password'} className="absolute right-3 top-1/2 -translate-y-1/2 rounded-md p-1 text-slate-500 hover:text-purple-800 focus:outline-none focus:ring-2 focus:ring-purple-500">
      {visible ? <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="M3 3l18 18"/><path d="M10.6 10.6a2 2 0 002.8 2.8"/><path d="M9.9 4.2A10.8 10.8 0 0112 4c5.5 0 9 5 9 5a16.7 16.7 0 01-2.1 2.6M6.6 6.6C4.4 8 3 10 3 10s3.5 5 9 5c1 0 1.9-.2 2.7-.4"/></svg> : <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true"><path d="M3 12s3.5-5 9-5 9 5 9 5-3.5 5-9 5-9-5-9-5z"/><circle cx="12" cy="12" r="2.5"/></svg>}
    </button>
  </div>
}
