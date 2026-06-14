import Image from 'next/image'
import Link from 'next/link'

export default function PublicNav(){
  return (
    <header className="sticky top-0 z-50 glass">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-5 py-3">
        <Link href="/" className="flex items-center gap-3">
          <Image src="/ailife-logo.png" alt="AILIFE logo" width={54} height={54} className="rounded-xl object-cover"/>
          <div>
            <div className="text-lg font-black text-purple-950">AILIFE Empowerment</div>
            <div className="text-xs font-semibold text-slate-500">Digital Microfinance Platform</div>
          </div>
        </Link>
        <nav className="flex items-center gap-3 text-sm font-bold">
          <Link href="/onboard" className="hidden sm:inline text-purple-900">Open Account</Link>
          <Link href="/board-login" className="hidden md:inline text-purple-900">Board/Investor</Link>
          <Link href="/admin-login" className="hidden md:inline text-purple-900">Admin</Link>
          <Link href="/login" className="btn btn-primary">Staff Login</Link>
        </nav>
      </div>
    </header>
  )
}
