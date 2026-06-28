export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Double-Entry Ledger' subtitle='Ledger entries linked to journals, accounts, branches, customers and loans.' table='ledger_entries' cols={['id','journal_id','account_id','debit','credit','branch_id','customer_id','loan_id','created_at']} moneyCols={['debit','credit']}/>} 
