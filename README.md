# AILIFE Empowerment Platform v3.1 — Render PostgreSQL Edition

This version removes Supabase completely. The platform is designed to sit in one Render account:

- Render Web Service: Next.js application
- Render PostgreSQL: backend database
- `ailifeempowerment.com`: public website/app domain

## What is included

- Next.js App Router frontend
- Render PostgreSQL database schema
- Staff login backed by PostgreSQL
- Optional authenticator-app 2FA
- Double-entry ledger
- Maker-checker transaction controls
- Atomic transaction approval function
- Fraud/risk alert tables and rules foundation
- SMS/email notification outbox tables
- KYC document metadata vault
- Branch cash management
- Agent banking tables
- Regulatory/board reporting views

## Deploy on Render

### 1. Create Render PostgreSQL

Create a PostgreSQL instance named:

`ailife-empowerment-db`

Copy the **Internal Database URL**.

### 2. Load the database

Use Render Shell or local `psql`:

```bash
psql "$DATABASE_URL" -f database/schema.sql
```

### 3. Create your first admin

Run the seed/admin SQL in `database/schema.sql`, then update the admin password hash using the helper route/script you choose for production. The app uses `staff_profiles.password_hash` for login.

### 4. Create Render Web Service

Build command:

```bash
npm install && npm run build
```

Start command:

```bash
npm start
```

Environment variables:

```env
DATABASE_URL=your_render_internal_database_url
AUTH_SECRET=long_random_secret
ENABLE_2FA=true
PGSSLMODE=disable
NEXT_PUBLIC_SITE_URL=https://ailifeempowerment.com
```

### 5. Connect domains

Recommended:

- `ailifeempowerment.com` → main app
- `www.ailifeempowerment.com` → main app
- `admin.ailifeempowerment.com` → same app dashboard route, optional later

## Important production note

This is a strong launch foundation, but real money movement requires bank/payment integrations, compliance review, penetration testing, disaster recovery testing, and operational sign-off before live customer funds are processed.

## v3.2 AILIFE-specific configuration added

This package now includes the owner-provided operational setup:

- Osun branches: Ede, Osogbo, Owode, Head Office
- Ibadan branches: Ibadan 1, Ibadan 2
- Port Harcourt branches: Rumudara active; Rumukurushi and Eneka inactive
- Governance, operations and administration hierarchy
- Daily Loan: ₦20,000–₦250,000, 25–30 days, 20% flat
- Weekly Loan: ₦50,000–₦500,000, 12–16 weeks, 20% flat
- Monthly Loan: from ₦200,000, 3–6 months, 10% flat monthly
- Fees: 2% risk premium, 1% management fee, 1% processing/bank charges
- Default penalty: 5% flat monthly on overdue amount
- Approval policy: Credit Officer processes, Branch Manager recommends, Area Manager approves up to ₦400k, Program Director approves above ₦400k, Branch Manager disburses
- Staff onboarding cases and required onboarding checklist
- Client onboarding cases and required KYC/guarantor/business verification checklist
- Staff training modules for platform use, onboarding, loans, collections, fraud governance and reporting

Keep updating `database/schema.sql` as the owner provides savings products, repayment channels, staff list and SMS/payment provider details.
