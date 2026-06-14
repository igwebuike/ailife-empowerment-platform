import Link from 'next/link'
import { LayoutDashboard, Users, Banknote, ReceiptText, ShieldAlert, UserCog, BarChart3, Settings, Scale, CheckCircle2, Warehouse, Store, FileText, Bell, Building2, GraduationCap, SearchCheck, Settings2, BrainCircuit, ClipboardList, ClipboardCheck, Network, Landmark } from 'lucide-react'
import LogoutButton from './LogoutButton'
const nav=[
 ['/dashboard','Command Center',LayoutDashboard],
 ['/dashboard/branches','Branches',Building2],
 ['/dashboard/org-structure','Org Structure',Network],
 ['/dashboard/customers','Customers/KYC',Users],
 ['/dashboard/client-onboarding','Client Onboarding',ClipboardCheck],
 ['/dashboard/loans','Loans',Banknote],
 ['/dashboard/loan-products','Loan Products',Landmark],
 ['/dashboard/approval-rules','Approval Rules',CheckCircle2],
 ['/dashboard/transactions','Transactions',ReceiptText],
 ['/dashboard/ledger','Double-Entry Ledger',Scale],
 ['/dashboard/approvals','Maker-Checker',CheckCircle2],
 ['/dashboard/cash','Branch Cash',Warehouse],
 ['/dashboard/agents','Agent Banking',Store],
 ['/dashboard/documents','KYC Documents',FileText],
 ['/dashboard/notifications','SMS/Email Outbox',Bell],
 ['/dashboard/credit-bureau','Credit Bureau',SearchCheck],
 ['/dashboard/credit-config','Bureau Config',Settings2],
 ['/dashboard/risk-scoring','Risk Scoring',BrainCircuit],
 ['/dashboard/manual-credit-review','Manual Credit Review',ClipboardList],
 ['/dashboard/alerts','Fraud Alerts',ShieldAlert],
 ['/dashboard/staff','Staff & Roles',UserCog],
 ['/dashboard/staff-onboarding','Staff Onboarding',ClipboardCheck],
 ['/dashboard/training','Staff Training',GraduationCap, SearchCheck, Settings2, BrainCircuit, ClipboardList],
 ['/dashboard/onboarding-checklist','Onboarding Checklists',ClipboardCheck],
 ['/dashboard/reports','Regulatory Reports',BarChart3],
 ['/dashboard/settings','Governance',Settings]
]
export default function AppShell({children}){return <div className="min-h-screen bg-slate-50"><aside className="fixed inset-y-0 left-0 hidden w-80 overflow-y-auto border-r bg-white p-5 lg:block"><div className="mb-8"><div className="text-2xl font-black text-purple-950">AILIFE Command</div><div className="text-sm text-slate-500">Remote Monitoring Center</div></div><div className="space-y-1">{nav.map(([href,label,Icon])=><Link key={href} href={href} className="flex items-center gap-3 rounded-2xl px-4 py-3 font-bold text-slate-700 hover:bg-purple-50 hover:text-purple-900"><Icon size={18}/>{label}</Link>)}</div><div className="mt-6"><LogoutButton/></div></aside><main className="lg:pl-80"><div className="mx-auto max-w-7xl p-5 lg:p-8">{children}</div></main></div>}
