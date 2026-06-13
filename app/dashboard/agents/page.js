import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Agent Banking' subtitle='Remote agents for onboarding, deposit collection and loan repayment collection.' table='agents' cols=['agent_code', 'business_name', 'contact_name', 'phone', 'location', 'status', 'daily_limit'] moneyCols=['daily_limit']/>}
