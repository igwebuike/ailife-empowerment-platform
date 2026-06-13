import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Fraud & Risk Alerts' subtitle='Duplicate BVN/NIN, unusual withdrawals, velocity rules and insider-risk flags.' table='risk_alerts' cols={['alert_type','severity','customer_name','description','status','created_at']} />}
