import { PiggyBank, Calendar, Percent, Wallet } from 'lucide-react'

const products = [
  {
    name: 'Daily Savings',
    minimum: '₦200 and above',
    period: 'Monthly cycle',
    interest: 'No interest paid',
    rule: 'AILIFE takes the first savings paid. Client receives savings at month end and starts again unless on loan or chooses to continue saving.'
  },
  {
    name: 'Weekly Savings',
    minimum: '₦1,000 and above',
    period: '4 months, 6 months, or 1 year',
    interest: '3% per annum for 6 months and above',
    rule: 'Below 6 months attracts charges equal to the first installment.'
  },
  {
    name: 'Monthly Savings',
    minimum: '₦10,000 and above',
    period: '12 months and above',
    interest: '3% per annum',
    rule: 'Withdrawal after agreed savings period.'
  },
  {
    name: 'Target Savings',
    minimum: 'Any amount',
    period: 'Flexible target period',
    interest: 'Based on agreed terms',
    rule: 'Client saves toward a personal target amount.'
  },
  {
    name: 'Fixed Deposit',
    minimum: '₦200,000 and above',
    period: '3 months, 6 months, or 1 year',
    interest: 'Depends on amount and tenor',
    rule: 'Withdrawal at maturity unless otherwise agreed.'
  }
]

export default function SavingsProducts(){
  return (
    <div>
      <div className="mb-8">
        <div className="inline-flex rounded-full bg-purple-100 px-4 py-2 text-sm font-black text-purple-800">Savings Configuration</div>
        <h1 className="mt-4 text-4xl font-black text-purple-950">AILIFE Savings Products</h1>
        <p className="mt-3 max-w-3xl text-slate-600">Configured savings products for daily savers, weekly savers, monthly savers, target savings and fixed deposits.</p>
      </div>

      <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
        {products.map((p)=>(
          <div key={p.name} className="card rounded-3xl bg-white p-6 shadow-sm">
            <PiggyBank className="text-purple-800" />
            <h2 className="mt-4 text-2xl font-black text-purple-950">{p.name}</h2>
            <div className="mt-5 space-y-4 text-sm">
              <div className="flex gap-3"><Wallet className="shrink-0 text-yellow-500" size={18}/><div><b>Minimum:</b><br/>{p.minimum}</div></div>
              <div className="flex gap-3"><Calendar className="shrink-0 text-yellow-500" size={18}/><div><b>Period:</b><br/>{p.period}</div></div>
              <div className="flex gap-3"><Percent className="shrink-0 text-yellow-500" size={18}/><div><b>Interest:</b><br/>{p.interest}</div></div>
            </div>
            <div className="mt-5 rounded-2xl bg-purple-50 p-4 text-sm font-semibold leading-6 text-purple-950">{p.rule}</div>
          </div>
        ))}
      </div>
    </div>
  )
}
