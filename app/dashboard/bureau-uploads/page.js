export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Credit Bureau Contributor Queue' subtitle='Queue for reporting AILIFE loans, borrowers, repayments, defaults and closures to CreditRegistry after subscriber credentials are approved.' table='bureau_upload_queue' cols={['upload_type', 'source_table', 'status', 'provider_code', 'upload_id', 'error_message', 'created_at', 'processed_at']} moneyCols={[]}/>}
