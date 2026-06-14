import { NextResponse } from 'next/server'
import crypto from 'crypto'
import { requireUser } from '@/lib/auth'
import { query } from '@/lib/db'
function base32(bytes=20){const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';let bits='',out='';for(const b of crypto.randomBytes(bytes))bits+=b.toString(2).padStart(8,'0');for(let i=0;i<bits.length;i+=5)out+=alphabet[parseInt(bits.slice(i,i+5).padEnd(5,'0'),2)];return out}
export async function POST(){const user=await requireUser();const secret=base32();await query('update staff_profiles set totp_secret=$1,mfa_required=true where id=$2',[secret,user.id]);const issuer='AILIFE Empowerment';const label=encodeURIComponent(`${issuer}:${user.email}`);const uri=`otpauth://totp/${label}?secret=${secret}&issuer=${encodeURIComponent(issuer)}&algorithm=SHA1&digits=6&period=30`;return NextResponse.json({secret,uri})}
