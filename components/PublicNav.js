import Link from 'next/link'
export default function PublicNav(){
  return <header className="sticky top-0 z-40 border-b border-slate-200 bg-white/95 backdrop-blur">
    <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-4">
      <Link href="/" className="flex items-center gap-3">
        <img src="/ailife-logo.png" alt="AILIFE" className="h-9 w-auto"/>
        <div><div className="text-xl font-black text-purple-950">AILIFE Empowerment</div><div className="text-sm font-semibold text-slate-500">Digital Microfinance Platform</div></div>
      </Link>
      <nav className="hidden items-center gap-7 font-black text-purple-900 md:flex">
        <Link href="/onboard">Open Account</Link>
        <Link href="/services">Credit Services</Link>
        <Link href="/investor-login">Investor</Link>
        <Link href="/admin-login">Admin</Link>
        <Link href="/login" className="rounded-full bg-gradient-to-r from-purple-800 to-violet-700 px-6 py-3 text-white shadow-lg shadow-purple-900/20">Staff Login</Link>
      </nav>
    </div>
  </header>
}
