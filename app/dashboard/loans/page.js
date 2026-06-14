export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Loans' subtitle='Loan portfolio, approvals, disbursement and repayment monitoring.' table='loans' cols={['customer_name','principal','outstanding_balance','interest_rate','term_weeks','status','due_date','created_at']} moneyCols={['principal','outstanding_balance']} />}
