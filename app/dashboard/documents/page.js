import DataPage from '@/components/DataPage'
export default function Page(){return <DataPage title='KYC Document Vault' subtitle='NIN, BVN slip, photos, guarantor forms and uploaded verification evidence.' table='kyc_documents' cols=['doc_type', 'file_name', 'verification_status', 'verified_by', 'created_at'] moneyCols=[]/>}
