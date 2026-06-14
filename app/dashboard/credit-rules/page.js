import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Internal Risk Rules' subtitle='Risk rules used by AILIFE internal scoring while external credit bureau access is pending.' table='internal_risk_rules' cols={['rule_code','title','points','severity','active','created_at']} moneyCols={[]}/>}
