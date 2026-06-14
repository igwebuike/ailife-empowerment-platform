export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Manual Credit Review Workflow' subtitle='Compliance/credit team review queue for loans requiring human decision before approval or disbursement.' table='manual_credit_reviews' cols={['status','recommendation','conditions','notes','created_at','reviewed_at']} moneyCols={[]}/>}
