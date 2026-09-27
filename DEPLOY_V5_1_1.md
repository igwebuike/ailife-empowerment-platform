# AIBLE v5.1.1 Rules + Credit History Upgrade

This is an overlay patch for the already-deployed v5.1 source. It does not include package-lock.json, so keep the clean public-registry lockfile already generated locally.

## 1. Copy patch files into the project
Copy the contents of this patch over `C:\Users\eugen\Desktop\ailife-empowerment-platform` and replace matching files.

## 2. Run migration 005 first
From CMD in the project folder:

`"C:\Program Files\PostgreSQL\18\bin\psql.exe" "YOUR_RENDER_EXTERNAL_DATABASE_URL" -v ON_ERROR_STOP=1 -f "database\005_v5_1_1_rules_credit_history.sql"`

Expected final line: `COMMIT`.

## 3. Build locally
`npm run build`

## 4. Review Git changes
`git status`

Then commit and push only after the migration and build succeed.

## New pages
- `/dashboard/decision-rules` — explainable AIBLE decision rules engine.
- `/dashboard/credit-history` — Customer 360 credit event history and decision trace.
- `/dashboard/admin/migrations` — safer controlled SQL operations with affected-row preview.

## Important
The internal AIBLE score is not a FICO score. The interface is inspired by business-rules/decision-engine workflows, while AIBLE keeps its own rule versions, inputs, outputs, and audit trail.

## Data & Transaction Workbench enhancement
Run migration 006 after 005:

```cmd
"C:\Program Files\PostgreSQL\18\bin\psql.exe" "YOUR_RENDER_EXTERNAL_DATABASE_URL" -v ON_ERROR_STOP=1 -f "database\006_v5_1_1_data_workbench.sql"
```

Then verify `/dashboard/data-workbench`. The Workbench uses allow-listed datasets, branch scoping, parameterized queries, role-gated controlled writes and audit logging. It does not expose arbitrary SQL to staff. Financial records created there enter `pending` status for existing approval controls.
