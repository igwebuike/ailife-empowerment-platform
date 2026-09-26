export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Fraud & Risk Alerts' subtitle='Duplicate BVN/NIN, unusual withdrawals, velocity rules and insider-risk flags.' table='risk_alerts' cols={['alert_type','severity','message','related_table','status','created_at']} />}
