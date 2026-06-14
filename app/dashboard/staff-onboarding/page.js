export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Staff Onboarding' subtitle='New staff onboarding cases, role assignment, branch assignment, MFA and activation status.' table='staff_onboarding_cases' cols={['full_name', 'role', 'email', 'phone', 'status', 'start_date', 'created_at']} moneyCols={[]}/>}
