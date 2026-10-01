import { NextResponse } from 'next/server';import { verifyOrg,setOrgSession } from '@/lib/orgAuth'
export async function POST(req){const d=await req.json(),o=await verifyOrg(d.email||'',d.password||'');if(!o)return NextResponse.json({error:'Invalid group email or password.'},{status:401});await setOrgSession(o);return NextResponse.json({ok:true})}
