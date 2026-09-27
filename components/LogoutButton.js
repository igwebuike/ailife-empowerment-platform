
'use client'
export default function LogoutButton(){async function logout(){await fetch('/api/logout',{method:'POST'}); location.href='/login'} return <button onClick={logout} className="w-full rounded-2xl border border-purple-200 bg-purple-50 px-4 py-3 text-sm font-black text-purple-900 hover:bg-purple-100">Logout</button>}
