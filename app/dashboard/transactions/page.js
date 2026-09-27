export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Transactions' subtitle='Deposits, withdrawals, repayments, reversals and approved cash movements.' table='transactions' cols={['reference','transaction_type','type','amount','channel','status','transaction_date','created_at']} moneyCols={['amount']} />}
