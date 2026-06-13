import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Tasks' subtitle='Remote operations task tracking and staff accountability.' table='tasks' cols={['title','status','priority','created_at']} />}
