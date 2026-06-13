import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Staff & Roles' subtitle='Remote staff access, role governance, branches and status monitoring.' table='staff_profiles' cols={['full_name','email','phone','role','branch','mfa_required','status','created_at']} />}
