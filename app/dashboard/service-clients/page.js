export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Service Clients' subtitle='Smaller MFIs, cooperatives, NGOs and lenders that subscribe to AILIFE credit screening and SaaS services.' table='service_clients' cols={['organization_name', 'client_type', 'contact_name', 'email', 'phone', 'status', 'plan_code', 'created_at']} moneyCols={[]}/>}
