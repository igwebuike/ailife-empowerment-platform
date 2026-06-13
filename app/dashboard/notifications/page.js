import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='SMS / Email Outbox' subtitle='Queued alerts for OTPs, deposits, withdrawals, payments and overdue loans.' table='notification_outbox' cols=['channel', 'recipient', 'subject', 'status', 'provider', 'attempts', 'created_at'] moneyCols=[]/>}
