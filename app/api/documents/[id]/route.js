import { NextResponse } from 'next/server'
import { query } from '@/lib/db'
import { getCurrentUser } from '@/lib/auth'
export async function GET(req,{params}){
 const user=await getCurrentUser(); if(!user)return NextResponse.json({error:'Unauthorized'},{status:401})
 const r=await query(`select d.file_name,b.mime_type,b.content from kyc_documents d join document_blobs b on b.kyc_document_id=d.id where d.id=$1 limit 1`,[params.id])
 if(!r.rowCount)return NextResponse.json({error:'Document not found'},{status:404})
 const x=r.rows[0]; return new NextResponse(x.content,{headers:{'Content-Type':x.mime_type,'Content-Disposition':`attachment; filename="${String(x.file_name||'document').replaceAll('"','')}"`,'Cache-Control':'private, no-store'}})
}
