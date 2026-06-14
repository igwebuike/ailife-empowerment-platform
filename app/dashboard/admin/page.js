import Link from 'next/link'
import { ShieldCheck, UserCog, Building2, PiggyBank, CreditCard, Settings, FileText } from 'lucide-react'

const cards = [
  {title:'Staff Management', href:'/dashboard/staff-management', icon:UserCog, desc:'Create staff, assign roles, branches, departments and permission levels.'},
  {title:'Branches', href:'/dashboard/branches', icon:Building2, desc:'Manage active and inactive branches across Osun, Oyo and Rivers State.'},
  {title:'Savings Products', href:'/dashboard/savings-products', icon:PiggyBank, desc:'Review daily, weekly, monthly, target savings and fixed deposit rules.'},
  {title:'Repayment Methods', href:'/dashboard/repayment-methods', icon:CreditCard, desc:'Manage cash, transfer and POS collection methods.'},
  {title:'Governance Settings', href:'/dashboard/settings', icon:Settings, desc:'Configure controls, approvals, audit requirements and operating policies.'},
  {title:'Reports', href:'/dashboard/reports', icon:FileText, desc:'Open daily, weekly, monthly, branch, staff, portfolio and board reports.'}
]

export default function AdminPortal(){
  return (
    <div>
      <div className="mb-8 rounded-3xl bg-purple-950 p-8 text-white shadow-xl">
        <ShieldCheck className="text-yellow-300" />
        <h1 className="mt-4 text-4xl font-black">AILIFE Admin Portal</h1>
        <p className="mt-3 max-w-3xl text-purple-100">Central configuration area for administrators to manage staff access, role permissions, branches, product rules, repayment methods and governance controls.</p>
      </div>
      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
        {cards.map(({title,href,icon:Icon,desc})=>(
          <Link key={title} href={href} className="card rounded-3xl bg-white p-6 shadow-sm hover:shadow-xl transition">
            <Icon className="text-purple-800" />
            <h2 className="mt-4 text-2xl font-black text-purple-950">{title}</h2>
            <p className="mt-2 leading-7 text-slate-600">{desc}</p>
          </Link>
        ))}
      </div>
    </div>
  )
}
