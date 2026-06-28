export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Credit Bureau' subtitle='CreditRegistry request log, consent, SMARTScore and report status.' table='credit_bureau_requests' cols={['id','customer_id','loan_application_id','request_type','provider','consent_given','request_status','smart_score','requested_by','requested_at','completed_at']} moneyCols={[]}/>} 
