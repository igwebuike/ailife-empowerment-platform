export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Loan Products' subtitle='Daily, weekly and monthly loan products with fees, tenor and penalty rules.' table='loan_products' cols={['product_code', 'product_name', 'min_amount', 'max_amount', 'interest_rate', 'interest_method', 'default_penalty_rate', 'status']} moneyCols={['min_amount', 'max_amount']}/>}
