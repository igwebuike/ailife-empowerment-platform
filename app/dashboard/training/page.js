import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Staff Training' subtitle='Required platform, governance, collections, reporting and fraud-control training modules.' table='training_modules' cols={['module_code', 'title', 'audience', 'required', 'status', 'created_at']} moneyCols={[]}/>}
