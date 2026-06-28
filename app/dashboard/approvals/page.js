export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Maker-Checker Approvals' subtitle='Approval workflow for loans, savings withdrawals, disbursements and governance actions.' table='approval_workflows' cols={['id','entity_type','entity_id','approval_stage','assigned_role','assigned_to','decision','decided_at','created_at']} moneyCols={[]}/>} 
