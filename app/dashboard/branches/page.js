export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Branches' subtitle='AILIFE active/inactive branches, states, areas and operational status.' table='branches' cols={['id','name','state','area','status','created_at']} moneyCols={[]}/>} 
