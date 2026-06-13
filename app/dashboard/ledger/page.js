import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Double-Entry Ledger' subtitle='Assets, liabilities, income, expenses and equity through journal entries.' table='ledger_entries' cols={['created_at', 'journal_id', 'account_id', 'debit', 'credit']} moneyCols={['debit', 'credit']}/>}
