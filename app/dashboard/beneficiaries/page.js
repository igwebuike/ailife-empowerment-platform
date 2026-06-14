export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Beneficiaries' subtitle='Legacy empowerment beneficiaries and program tracking.' table='beneficiaries' cols={['full_name','phone','community','status','created_at']} />}
