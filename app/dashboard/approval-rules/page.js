export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='AILIFE Approval Rules' subtitle='Credit officer processing, branch manager recommendation, area/program director approval and disbursement rules.' table='loan_approval_rules' cols={['rule_name', 'min_amount', 'max_amount', 'processor_role', 'recommender_role', 'approver_role', 'disburser_role', 'finance_release_required']} moneyCols={['min_amount', 'max_amount']}/>}
