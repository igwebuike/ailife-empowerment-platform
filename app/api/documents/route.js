import { NextResponse } from 'next/server'
import crypto from 'crypto'
import { query } from '@/lib/db'
import { getCurrentUser } from '@/lib/auth'

const MAX=8*1024*1024
const allowed=new Set(['application/pdf','image/jpeg','image/png','image/webp'])
export async function POST(req){
 const user=await getCurrentUser(); if(!user)return NextResponse.json({error:'Unauthorized'},{status:401})
 const f=await req.formData(), file=f.get('file'), customerId=Number(f.get('customer_id')), docType=String(f.get('doc_type')||'other')
 if(!customerId||!file||typeof file==='string')return NextResponse.json({error:'Customer and file are required'},{status:400})
 if(file.size>MAX)return NextResponse.json({error:'File must be 8 MB or smaller'},{status:400})
 if(!allowed.has(file.type))return NextResponse.json({error:'Only PDF, JPG, PNG and WebP files are allowed'},{status:400})
 const bytes=Buffer.from(await file.arrayBuffer()), sha=crypto.createHash('sha256').update(bytes).digest('hex')
 const client=await query('select id from customers where id=$1',[customerId]); if(!client.rowCount)return NextResponse.json({error:'Customer not found'},{status:404})
 const r=await query(`insert into kyc_documents(customer_id,doc_type,file_name,verification_status,created_at) values($1,$2,$3,'pending',now()) returning id`,[customerId,docType,file.name])
 await query(`insert into document_blobs(kyc_document_id,mime_type,size_bytes,sha256,content,uploaded_by) values($1,$2,$3,$4,$5,$6)`,[r.rows[0].id,file.type,file.size,sha,bytes,user.id])
 await query(`insert into audit_events(actor_id,action,entity_type,entity_id,metadata) values($1,'document.upload','kyc_document',$2,$3)`,[user.id,String(r.rows[0].id),JSON.stringify({file_name:file.name,doc_type:docType,sha256:sha})])
 return NextResponse.redirect(new URL('/dashboard/documents?uploaded=1',req.url),303)
}
