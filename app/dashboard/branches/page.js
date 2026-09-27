export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Branches' subtitle='AILIFE branch network and operational status.' table='branches' cols={['name','state','area','status','created_at']} />}
