export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Loans' subtitle='Loan portfolio, approvals, disbursement and repayment monitoring.' table='loans' cols={['id','customer_id','principal_amount','interest_amount','total_payable','outstanding_balance','disbursement_date','maturity_date','repayment_frequency','loan_status','created_at']} moneyCols={['principal_amount','interest_amount','total_payable','outstanding_balance']} />}
