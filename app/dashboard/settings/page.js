export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Governance Settings' subtitle='Organization and platform configuration.' table='organization_settings' cols={['id','setting_key','setting_value','created_at']} moneyCols={[]}/>} 
