export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Programs' subtitle='AILIFE programs, outreach, livelihood and monitoring activities.' table='programs' cols={['name','program_type','status','created_at']} />}
