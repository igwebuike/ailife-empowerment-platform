export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Loan Products' subtitle='Daily, weekly and monthly loan products with fees, tenor and penalty rules.' table='loan_products' cols={['id','name','product_type','minimum_amount','maximum_amount','interest_rate','interest_type','tenor_days','repayment_frequency','penalty_rate','status']} moneyCols={['minimum_amount','maximum_amount']}/>} 
