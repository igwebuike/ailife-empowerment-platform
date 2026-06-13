import AppShell from '@/components/AppShell'
import { requireUser } from '@/lib/auth'
export default async function DashboardLayout({children}){ await requireUser(); return <AppShell>{children}</AppShell> }
