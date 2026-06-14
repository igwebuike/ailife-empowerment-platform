export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Client Onboarding' subtitle='Client onboarding cases from branch, field, agent, online or phone channels.' table='client_onboarding_cases' cols={['full_name', 'phone', 'onboarding_channel', 'status', 'assigned_staff_id', 'created_at']} moneyCols={[]}/>}
