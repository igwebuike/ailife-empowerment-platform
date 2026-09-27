export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Maker-Checker Approvals' subtitle='Approval routing for loans, withdrawals, KYC and cash transfers.' table='approval_workflows' cols={['entity_type','entity_id','approval_stage','assigned_role','assigned_to','decision','comments','decided_at','created_at']} />}
