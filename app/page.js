import PublicNav from '@/components/PublicNav'
import Link from 'next/link'
import { ShieldCheck, Smartphone, Users, BellRing, LineChart, LockKeyhole, TrendingUp } from 'lucide-react'

const features = [
  ['Remote onboarding','Register customers anywhere with KYC, guarantor, BVN/NIN fields and documents.',Users],
  ['Savings + loans','Manage daily, weekly and monthly loans, daily savings, repayment schedules and collections.',Smartphone],
  ['Live transaction alerts','Trigger SMS/email/WhatsApp alerts for deposits, withdrawals, payments and overdue loans.',BellRing],
  ['Fraud monitoring','Detect duplicate customers, unusual withdrawals, maker-checker violations and risky staff actions.',ShieldCheck],
  ['Board reporting','Executive dashboards for portfolio, arrears, branch performance, audit trail and growth.',LineChart],
  ['2FA governance','Role-based access, approval workflow, audit logs and mandatory two-factor authentication.',LockKeyhole]
]

const metrics = [
  ['Deposits Today','₦0','Daily savings and repayment inflow'],
  ['Loan Portfolio','₦0','Outstanding active loan book'],
  ['PAR Risk','0%','Portfolio at risk / overdue loans'],
  ['Fraud Alerts','0','Open governance and fraud flags']
]

export default function Home(){
  return <>
    <PublicNav/>
    <section className="relative overflow-hidden bg-gradient-to-br from-purple-950 via-purple-900 to-slate-950 text-white">
      <div className="absolute inset-0 opacity-20 bg-[radial-gradient(circle_at_20%_20%,#facc15,transparent_30%),radial-gradient(circle_at_80%_10%,#a855f7,transparent_30%)]"/>
      <div className="relative mx-auto grid max-w-7xl gap-10 px-5 py-20 lg:grid-cols-2 lg:items-center">
        <div>
          <div className="mb-5 inline-flex rounded-full bg-yellow-400/20 px-4 py-2 text-sm font-black text-yellow-200 ring-1 ring-yellow-300/30">ailifeempowerment.com ready</div>
          <h1 className="text-5xl font-black tracking-tight lg:text-7xl">World-class digital microfinance for AILIFE.</h1>
          <p className="mt-6 max-w-xl text-lg leading-8 text-purple-100">A production-ready platform for customer onboarding, savings, loans, remote staff operations, fraud alerts, governance and executive monitoring.</p>
          <div className="mt-8 flex flex-wrap gap-3">
            <Link href="/onboard" className="btn btn-gold">Open Customer Account</Link>
            <Link href="/login" className="btn bg-white text-purple-950">Enter Staff Portal</Link>
            <Link href="/admin-login" className="btn bg-purple-800 text-white ring-1 ring-white/20">Admin Portal</Link>
          </div>
        </div>
        <div className="rounded-[2rem] bg-white p-6 text-slate-900 shadow-2xl ring-1 ring-white/30">
          <div className="mb-5 flex items-center justify-between">
            <div>
              <div className="text-sm font-bold uppercase tracking-widest text-purple-700">Command Center</div>
              <h2 className="text-2xl font-black text-purple-950">Executive Snapshot</h2>
            </div>
            <TrendingUp className="text-yellow-500" />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            {metrics.map(([label,value,desc]) => <div key={label} className="rounded-3xl border border-purple-100 bg-gradient-to-br from-purple-50 to-white p-5 shadow-sm">
              <div className="text-sm font-bold text-purple-700">{label}</div>
              <div className="mt-2 text-4xl font-black text-purple-950">{value}</div>
              <div className="mt-2 text-xs font-medium text-slate-500">{desc}</div>
            </div>)}
          </div>
          <div className="mt-5 rounded-3xl bg-purple-950 p-5 text-white">
            <div className="font-black text-yellow-300">Governance by design</div>
            <p className="mt-2 text-sm leading-6 text-purple-100">Maker-checker approvals, immutable audit logs, role separation and 2FA keep the institution investor-ready.</p>
          </div>
        </div>
      </div>
    </section>
    <section className="mx-auto max-w-7xl px-5 py-16">
      <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">{features.map(([t,d,Icon])=><div key={t} className="card p-6"><Icon className="text-purple-800"/><h3 className="mt-4 text-xl font-black">{t}</h3><p className="mt-2 text-slate-600">{d}</p></div>)}</div>
    </section>
    <footer className="border-t bg-white px-5 py-8">
      <div className="mx-auto flex max-w-7xl flex-col gap-2 text-sm font-semibold text-slate-600 md:flex-row md:items-center md:justify-between">
        <div>© AILIFE Empowerment Digital Microfinance Platform</div>
        <div>Customer Care: <a className="text-purple-900" href="tel:+2349060085384">+2349060085384</a> · Email: <a className="text-purple-900" href="mailto:ailife018@gmail.com">ailife018@gmail.com</a></div>
      </div>
    </footer>
  </>
}
