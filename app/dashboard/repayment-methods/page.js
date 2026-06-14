import { CreditCard, Banknote, Landmark } from 'lucide-react'

const methods = [
  {name:'Cash', icon:Banknote, desc:'Branch or field cash collections recorded by authorized staff.'},
  {name:'Transfer', icon:Landmark, desc:'Bank transfer repayment with reconciliation and payment confirmation.'},
  {name:'POS', icon:CreditCard, desc:'POS repayment collected at branch or through approved field officers.'}
]

export default function RepaymentMethods(){
  return (
    <div>
      <div className="mb-8">
        <div className="inline-flex rounded-full bg-purple-100 px-4 py-2 text-sm font-black text-purple-800">Collections</div>
        <h1 className="mt-4 text-4xl font-black text-purple-950">Repayment Methods</h1>
        <p className="mt-3 max-w-3xl text-slate-600">AILIFE currently supports customer repayment through cash, transfer and POS. Every collection should create an audit trail and customer alert.</p>
      </div>
      <div className="grid gap-5 md:grid-cols-3">
        {methods.map(({name,icon:Icon,desc})=>(
          <div key={name} className="card rounded-3xl bg-white p-6 shadow-sm">
            <Icon className="text-purple-800" size={30}/>
            <h2 className="mt-4 text-2xl font-black text-purple-950">{name}</h2>
            <p className="mt-3 leading-7 text-slate-600">{desc}</p>
            <div className="mt-5 rounded-2xl bg-green-50 p-4 text-sm font-bold text-green-900">Status: Active</div>
          </div>
        ))}
      </div>
    </div>
  )
}
