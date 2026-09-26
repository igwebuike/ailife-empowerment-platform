# AIBLE v5 — Digital Finance Infrastructure

A deployable Next.js/PostgreSQL upgrade of the AILIFE platform for internal MFI operations plus multi-tenant community-finance SaaS.

## v5 additions
- AIBLE Groups: tenants for ajo/esusu, cooperatives, associations, MFIs and SMEs
- Contribution plans/members/collections data model
- CreditRegistry adapter configuration
- Yellow Card integration scaffold (safe/off until approved credentials are supplied)
- AIBLE Proof scaffold for privacy-preserving hash anchoring (off by default)
- Password reset token flow; existing TOTP MFA retained
- Production auth-secret hardening
- PWA manifest for mobile-ready deployment
- Integration control center and payment-provider abstraction
- Existing loans, savings, double-entry ledger, maker-checker, KYC, fraud, staff training and reporting retained

## Deploy on Render
1. Push this folder to GitHub.
2. Create/attach Render PostgreSQL.
3. Run `database/schema.sql` against the database (safe to re-run; uses `if not exists`/upserts where designed).
4. Set `DATABASE_URL`, a long random `AUTH_SECRET`, `ENABLE_2FA=true`, `NODE_VERSION=20`, and `NEXT_PUBLIC_SITE_URL`.
5. Build command: `npm ci && npm run build`
6. Start command: `npm start`
7. Keep `CREDIT_REGISTRY_LIVE=false`, `YELLOW_CARD_LIVE=false`, and `BLOCKCHAIN_ANCHOR_ENABLED=false` until approved production credentials/compliance testing are complete.

## Important before real users
Change seeded passwords, enroll MFA, configure a real email/SMS provider for reset delivery, encrypt/restrict sensitive KYC data, configure backups/monitoring, run security testing, and validate regulatory/partner requirements for every money-movement feature.
