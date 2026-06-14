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


## v3.3 Credit Bureau Ready Upgrade

This build includes the deploy-now / activate-later credit bureau architecture:

- Credit Bureau Integration Module
- Credit Bureau Configuration screen
- Internal Risk Scoring Engine
- Manual Credit Review Workflow
- CreditRegistry/CRC/FirstCentral provider placeholders
- API routes for creating placeholder bureau checks and calculating internal risk scores

Live bureau calls remain disabled until AILIFE completes provider registration and receives official credentials. Use Render environment variables for secrets; do not store raw API keys in the database.

Recommended deployment flow:

1. Deploy app and database on Render.
2. Run `database/schema.sql` against Render PostgreSQL.
3. Use Internal Risk Scoring + Manual Credit Review immediately.
4. After CreditRegistry approval, add credentials in Render environment variables.
5. Update the Credit Bureau Configuration screen/table to enable production checks.


## v4.0 Phase 1 to Phase 4 Expansion

This build now supports the full vision:

### Phase 1 — AILIFE Microfinance Operations
- Staff, branches, customers, onboarding, loans, savings, collections, reports and governance.

### Phase 2 — Credit Bureau Contributor
- Bureau upload queue for persons, businesses, accounts, account history, defaults, closures and corrections.
- Designed for CreditRegistry AutoCred activation after credentials are approved.

### Phase 3 — Credit Risk & Verification Services
- Credit Services Marketplace.
- Service client onboarding for smaller MFIs, cooperatives, NGOs and lenders.
- Customer consent forms.
- Paid internal risk reports and future bureau-enabled checks.
- Billing/order tracking.

### Phase 4 — Microfinance SaaS Platform
- SaaS subscriptions for smaller lenders.
- API client access placeholders.
- Revenue dashboard.
- Plan-based limits for users and branches.

Important: bureau data resale must be permitted by CreditRegistry and applicable law before enabling bureau-backed resale. The platform can immediately sell AILIFE internal risk reports and operational SaaS services while live bureau credentials and permissions are pending.
