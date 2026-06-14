export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Customer Consent Forms' subtitle='Consent records proving the borrower authorized AILIFE or an approved service client to perform credit/risk checks.' table='customer_consents' cols={['customer_name', 'phone', 'consent_type', 'status', 'signed_at', 'expires_at', 'created_at']} moneyCols={[]}/>}
