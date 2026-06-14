import PublicNav from '@/components/PublicNav'
import Link from 'next/link'
import { ShieldCheck } from 'lucide-react'

export default function AdminLogin(){
  return (
    <>
      <PublicNav/>
      <main className="min-h-screen bg-slate-50 px-5 py-20">
        <div className="mx-auto max-w-xl rounded-3xl bg-white p-8 shadow-xl ring-1 ring-slate-200">
          <ShieldCheck className="text-purple-800" size={34}/>
          <h1 className="mt-5 text-4xl font-black text-purple-950">Admin Portal Access</h1>
          <p className="mt-4 text-lg leading-8 text-slate-600">System administrators can manage platform configuration, staff setup, roles, branch access, savings products, repayment methods and governance settings.</p>
          <form className="mt-8 space-y-5">
            <label className="block space-y-2"><span className="font-bold">Admin Email</span><input className="input" type="email" placeholder="admin@ailifeempowerment.com" /></label>
            <label className="block space-y-2"><span className="font-bold">Password</span><input className="input" type="password" /></label>
            <label className="block space-y-2"><span className="font-bold">2FA Code</span><input className="input" placeholder="Required when MFA is enabled" /></label>
            <Link href="/dashboard/admin" className="btn btn-primary w-full justify-center text-center">Enter Admin Portal</Link>
          </form>
          <div className="mt-5 flex justify-between text-sm font-bold text-purple-900">
            <Link href="/login">Staff Login</Link>
            <Link href="/board-login">Board / Investor Login</Link>
          </div>
        </div>
      </main>
    </>
  )
}
