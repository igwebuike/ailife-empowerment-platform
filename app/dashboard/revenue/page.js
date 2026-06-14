export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Revenue Dashboard' subtitle='Track revenue from credit checks, risk reports, SaaS subscriptions and implementation services.' table='revenue_events' cols={['event_type', 'customer_name', 'amount', 'currency', 'status', 'created_at']} moneyCols={['amount']}/>}
