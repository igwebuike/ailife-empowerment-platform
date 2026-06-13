import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Onboarding Checklists' subtitle='Required onboarding steps for new clients and new staff members.' table='onboarding_checklist_items' cols={['checklist_type', 'item_code', 'title', 'required', 'sort_order']} moneyCols={[]}/>}
