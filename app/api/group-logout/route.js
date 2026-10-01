import { NextResponse } from 'next/server';import { clearOrgSession } from '@/lib/orgAuth'
export async function POST(req){await clearOrgSession();return NextResponse.redirect(new URL('/group-login',req.url),303)}
