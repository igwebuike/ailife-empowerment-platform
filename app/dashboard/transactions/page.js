import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Transactions' subtitle='Deposits, withdrawals, repayments, reversals and approved cash movements.' table='transactions' cols={['reference','customer_name','type','amount','channel','status','created_at']} moneyCols={['amount']} />}
