# AIBLE v5.1 Operational GUI Upgrade

## What changed
- Operations Center: guided staff forms execute controlled server-side SQL.
- KYC Document Vault: authenticated PDF/image upload and private download.
- Groups / Ajo / Esusu: group, member, plan and contribution workflows.
- Migration Center: admin-only schema health checks and predefined reconciliation actions.
- Legacy compatibility: KYC `created_at`; transaction `type/status/channel/customer_name`; resilient table reads.
- Existing production display mappings corrected for branches, loan products, loans, approvals and transactions.
- Audit events are written for document uploads and Operations Center writes.

## Production database
Back up first, then run:

`"C:\Program Files\PostgreSQL\18\bin\psql.exe" "YOUR_RENDER_EXTERNAL_DATABASE_URL" -v ON_ERROR_STOP=1 -f "database\004_v5_operational_compatibility.sql"`

Expected final output: `COMMIT`.

## Git / Render
After the migration succeeds:

```
git add .
git commit -m "AIBLE v5.1 operational workflows and migration center"
git push origin main
```

Render Auto-Deploy should build the pushed commit.

## Post-deploy smoke test
1. Admin login and Command Center.
2. Operations Center.
3. KYC Documents: upload a small test PDF/image and open it while logged in.
4. Groups: create a test group, member, plan, then record a contribution.
5. Migration Center: Analyze Database only; confirm core schema ready.
6. Branches, Loan Products, Loans, Transactions and Maker-Checker pages.

## Security notes
- No arbitrary SQL console is exposed to browser users.
- Migration actions are restricted to `admin` and `executive_director`.
- Document download requires an authenticated session.
- Uploads are limited to PDF/JPG/PNG/WebP and 8 MB.
- Document bytes are stored privately in PostgreSQL for this deployment, avoiding public URLs and ephemeral Render filesystem loss. For large-scale document volume, migrate blob content to a private object store later while preserving the same metadata/audit model.
