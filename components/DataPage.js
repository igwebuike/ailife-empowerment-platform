
import { rows } from '@/lib/db'

function money(v){return v==null?'—':`₦${Number(v).toLocaleString()}`}
function fmt(v){ if(v==null) return '—'; if(typeof v==='number') return String(v); if(String(v).match(/^\d{4}-\d{2}-\d{2}T/)) return new Date(v).toLocaleString(); return String(v)}
export default async function DataPage({title,subtitle,table,cols=[],moneyCols=[]}){
  let data=[]; let error=null
  try{ data = await rows(table,100) }catch(e){ error=e }
  return <div><div className="flex flex-wrap items-center justify-between gap-4"><div><h1 className="text-4xl font-black text-purple-950">{title}</h1><p className="mt-2 text-slate-600">{subtitle}</p>{error&&<p className="mt-3 rounded-xl bg-red-50 p-3 text-sm text-red-700">{error.message}</p>}</div><span className="badge bg-purple-100 text-purple-900">{data.length} records</span></div><div className="card mt-8 overflow-hidden"><div className="overflow-x-auto"><table className="w-full text-left text-sm"><thead className="bg-slate-100 text-slate-600"><tr>{cols.map(c=><th key={c} className="px-4 py-3 font-black">{c.replaceAll('_',' ').toUpperCase()}</th>)}</tr></thead><tbody>{data.length?data.map((r,i)=><tr key={r.id||i} className="border-t">{cols.map(c=><td key={c} className="px-4 py-3">{moneyCols.includes(c)?money(r[c]):fmt(r[c])}</td>)}</tr>):<tr><td className="px-4 py-8 text-slate-500" colSpan={cols.length}>No records yet. Run database/schema.sql in Render PostgreSQL and add records.</td></tr>}</tbody></table></div></div></div>
}
