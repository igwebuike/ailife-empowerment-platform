import { NextResponse } from 'next/server'
import crypto from 'crypto'
import { requireUser } from '@/lib/auth'
import { query } from '@/lib/db'
function base32(bytes=20){const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';let bits='',out='';for(const b of crypto.randomBytes(bytes))bits+=b.toString(2).padStart(8,'0');for(let i=0;i<bits.length;i+=5)out+=alphabet[parseInt(bits.slice(i,i+5).padEnd(5,'0'),2)];return out}
function base32ToBuffer(v=''){const alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';let bits='',bytes=[];for(const ch of String(v).replace(/=+$/,'').replace(/\s/g,'').toUpperCase()){const n=alphabet.indexOf(ch);if(n<0)continue;bits+=n.toString(2).padStart(5,'0')}for(let i=0;i+8<=bits.length;i+=8)bytes.push(parseInt(bits.slice(i,i+8),2));return Buffer.from(bytes)}
function hotp(secret,counter){const buf=Buffer.alloc(8);buf.writeBigUInt64BE(BigInt(counter));const h=crypto.createHmac('sha1',base32ToBuffer(secret)).update(buf).digest();const o=h[h.length-1]&15;const n=((h[o]&127)<<24)|(h[o+1]<<16)|(h[o+2]<<8)|h[o+3];return String(n%1000000).padStart(6,'0')}
function verifyTotp(token,secret){if(!secret||!token)return false;const step=Math.floor(Date.now()/1000/30);return[-1,0,1].some(w=>hotp(secret,step+w)===String(token).trim())}
export async function POST(){const user=await requireUser();const secret=base32();const issuer='AILIFE Empowerment';const label=encodeURIComponent(`${issuer}:${user.email}`);const uri=`otpauth://totp/${label}?secret=${secret}&issuer=${encodeURIComponent(issuer)}&algorithm=SHA1&digits=6&period=30`;return NextResponse.json({secret,uri})}
export async function PUT(req){const user=await requireUser();const {secret,otp}=await req.json();if(!verifyTotp(otp,secret))return NextResponse.json({error:'Invalid authenticator code. Wait for a new 6-digit code and try again.'},{status:400});await query('update staff_profiles set totp_secret=$1,mfa_required=true where id=$2',[secret,user.id]);return NextResponse.json({ok:true})}
