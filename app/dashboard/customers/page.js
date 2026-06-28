export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Customers' subtitle='KYC, onboarding, customer risk and branch assignment.' table='customers' cols={['id','full_name','phone','branch','loan_product','bvn','nin','business_type','requested_amount','status','credit_bureau_status','created_at']} moneyCols={['requested_amount']} />}
