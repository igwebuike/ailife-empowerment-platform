export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Future API Access' subtitle='API access management for service clients after legal, privacy and bureau authorization requirements are satisfied.' table='api_clients' cols={['client_name', 'environment', 'status', 'rate_limit_per_day', 'last_used_at', 'created_at']} moneyCols={[]}/>}
