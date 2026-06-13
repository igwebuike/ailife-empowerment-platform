import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Customers' subtitle='KYC, onboarding, customer risk and branch assignment.' table='customers' cols={['customer_no','full_name','phone','bvn','nin','branch','status','risk_score','created_at']} />}
