export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Documents' subtitle='Customer, guarantor, staff and loan document register.' table='documents' cols={['id','owner_type','owner_id','document_name','document_type','document_url','uploaded_by','created_at']} moneyCols={[]}/>} 
