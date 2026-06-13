import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Branches' subtitle='AILIFE active/inactive branches, states, areas and operational status.' table='branches' cols={['branch_code', 'name', 'state', 'area', 'status', 'created_at']} moneyCols={[]}/>}
