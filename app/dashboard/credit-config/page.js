export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Credit Bureau Configuration' subtitle='Store provider readiness and credential references. Do not paste secrets into the database; use Render environment variables and references here.' table='credit_bureau_providers' cols={['provider_code','provider_name','environment','enabled','live_checks_allowed','base_url','notes','created_at']} moneyCols={[]}/>}
