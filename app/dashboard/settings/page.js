export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Governance Policies' subtitle='Live controls for 2FA, maker-checker, fraud thresholds, branch cash and document verification.' table='governance_policies' cols={['policy_name','policy_value','is_active','created_at']} moneyCols={[]}/>}
