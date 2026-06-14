# AILIFE Empowerment Platform v4.2

Production-ready Next.js + PostgreSQL platform package with customer onboarding, staff/admin/investor access, 2FA setup, loans, savings, approvals, reports, credit bureau readiness, credit services, and MFI SaaS modules.

## Deploy

1. Push to GitHub.
2. Create PostgreSQL database.
3. Run `database/schema.sql`.
4. Set environment variables.
5. Deploy the Next.js web service.

## Required environment variables

```env
DATABASE_URL=your_postgres_database_url
AUTH_SECRET=generate_a_long_random_secret
ENABLE_2FA=true
NODE_VERSION=20
NPM_CONFIG_LEGACY_PEER_DEPS=true
NPM_CONFIG_PRODUCTION=false
```

## Default test users

Default password: `ChangeMe123!`

- admin@ailifeempowerment.com
- investor@ailifeempowerment.com
- credit@ailifeempowerment.com
- branchmanager@ailifeempowerment.com

After first login, go to Governance Settings to generate a 2FA secret and add it to Google Authenticator or Microsoft Authenticator. Change all default passwords before real operations.
