export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='AILIFE Credit Services Marketplace' subtitle='Sell internal risk assessments and, after authorization, bureau-enabled checks to smaller MFIs/cooperatives with consent, billing and audit logs.' table='credit_service_requests' cols={['request_no', 'request_type', 'status', 'price_amount', 'payment_status', 'risk_band', 'decision', 'created_at']} moneyCols={['price_amount']}/>}
