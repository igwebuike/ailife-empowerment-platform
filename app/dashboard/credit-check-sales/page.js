export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Credit Check Sales' subtitle='Paid credit checks and risk reports sold through the AILIFE services portal.' table='credit_check_orders' cols={['order_no', 'customer_name', 'service_type', 'amount', 'status', 'payment_reference', 'created_at']} moneyCols={['amount']}/>}
