export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Microfinance SaaS Platform' subtitle='Subscription-based loan management, risk scoring, collections and reporting services for partner microfinance operators.' table='saas_subscriptions' cols={['client_name','plan_code','status','monthly_fee','users_allowed','branches_allowed','started_at','created_at']} moneyCols={['monthly_fee']}/>} 
