
'use client'
export default function LogoutButton(){async function logout(){await fetch('/api/logout',{method:'POST'}); location.href='/'} return <button onClick={logout} className="rounded-full bg-white/10 px-4 py-2 text-sm font-bold text-white hover:bg-white/20">Logout</button>}
