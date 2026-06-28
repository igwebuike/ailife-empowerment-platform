import Link from 'next/link'
import { LayoutDashboard, Users, Banknote, ReceiptText, ShieldAlert, UserCog, BarChart3, Settings, Scale, CheckCircle2, FileText, Bell, Building2, SearchCheck, Landmark, WalletCards } from 'lucide-react'
import LogoutButton from './LogoutButton'

const nav=[
 ['/dashboard','Command Center',LayoutDashboard],
 ['/dashboard/branches','Branches',Building2],
 ['/dashboard/staff-management','Staff Management',UserCog],
 ['/dashboard/staff','Staff & Roles',UserCog],
 ['/dashboard/customers','Customers/KYC',Users],
 ['/dashboard/loan-products','Loan Products',Landmark],
 ['/dashboard/loans','Loans',Banknote],
 ['/dashboard/approvals','Maker-Checker',CheckCircle2],
 ['/dashboard/transactions','Transactions',ReceiptText],
 ['/dashboard/ledger','Double-Entry Ledger',Scale],
 ['/dashboard/documents','Documents',FileText],
 ['/dashboard/notifications','Notifications',Bell],
 ['/dashboard/credit-bureau','Credit Bureau',SearchCheck],
 ['/dashboard/alerts','Fraud Alerts',ShieldAlert],
 ['/dashboard/reports','Reports',BarChart3],
 ['/dashboard/settings','Governance',Settings]
]
export default function AppShell({children}){return <div className="min-h-screen bg-slate-50"><aside className="fixed inset-y-0 left-0 hidden w-80 overflow-y-auto border-r bg-white p-5 lg:block"><div className="mb-8"><div className="text-2xl font-black text-purple-950">AIBLE Command</div><div className="text-sm text-slate-500">Digital Microfinance Platform</div></div><div className="space-y-1">{nav.map(([href,label,Icon])=><Link key={href} href={href} className="flex items-center gap-3 rounded-2xl px-4 py-3 font-bold text-slate-700 hover:bg-purple-50 hover:text-purple-900"><Icon size={18}/>{label}</Link>)}</div><div className="mt-6"><LogoutButton/></div></aside><main className="lg:pl-80"><div className="mx-auto max-w-7xl p-5 lg:p-8">{children}</div></main></div>}
