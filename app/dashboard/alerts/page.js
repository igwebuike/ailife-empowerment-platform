export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Fraud Alerts' subtitle='Duplicate identity, unusual withdrawal, staff risk and branch cash alerts.' table='fraud_alerts' cols={['id','alert_type','severity','description','customer_id','branch','status','created_at']} moneyCols={[]}/>} 
