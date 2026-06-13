import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Branch Cash Management' subtitle='Vault cash, teller cash, field cash and agent cash balances.' table='branch_cash_accounts' cols=['cash_type', 'balance', 'status', 'holder_staff_id', 'created_at'] moneyCols=['balance']/>}
