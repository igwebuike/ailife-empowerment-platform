export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Credit Bureau Configuration' subtitle='Manage bureau provider readiness, environment, status and credential references. Actual API secrets must remain in secure environment variables.' table='credit_bureau_providers' cols={['provider_code','provider_name','environment','enabled','live_checks_allowed','base_url','notes','created_at']} />}
