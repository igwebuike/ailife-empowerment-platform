export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Maker-Checker Approvals' subtitle='Mandatory approval workflow for loans, withdrawals, KYC and cash transfers.' table='approval_workflows' cols={['entity_type', 'status', 'requested_by', 'first_approved_by', 'second_approved_by', 'finance_released_by', 'created_at']} moneyCols={[]}/>}
