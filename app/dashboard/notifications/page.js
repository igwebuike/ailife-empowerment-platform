export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Notifications' subtitle='SMS, email and WhatsApp outbox for customer and staff alerts.' table='notifications' cols={['id','recipient_staff_id','customer_id','channel','subject','status','sent_at','created_at']} moneyCols={[]}/>} 
