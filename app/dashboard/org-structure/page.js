export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Organizational Structure' subtitle='Governance, operations and administration hierarchy.' table='organizational_units' cols={['department', 'role_name', 'reports_to', 'level_no', 'created_at']} moneyCols={[]}/>}
