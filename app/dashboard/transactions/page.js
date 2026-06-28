export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Transactions' subtitle='Deposits, withdrawals, disbursements, repayments and adjustments.' table='transactions' cols={['id','customer_id','loan_id','branch_id','transaction_type','amount','reference','transaction_date','created_at']} moneyCols={['amount']}/>} 
