export const dynamic = 'force-dynamic'
import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='Staff & Roles' subtitle='Remote staff access, role governance, branches and status monitoring.' table='staff_profiles' cols={['id','full_name','email','phone','department','role','branch_id','branch','area','approval_limit','mfa_required','status','created_at']} moneyCols={['approval_limit']} />}
