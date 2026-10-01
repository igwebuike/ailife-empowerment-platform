# AIBLE 5.2 deployment

## Included fixes/features
- Functional Staff Onboarding form using the existing `/api/staff` security model.
- Temporary first-login password, role/branch assignment and MFA requirement.
- `My Workspace` landing page for staff and role-filtered navigation.
- Staff login now lands on `/dashboard/workspace`.
- FX rate administration at `/dashboard/fx` and public estimator at `/fx`.
- Ajo/group self-registration at `/group-signup`, login at `/group-login`, private dashboard at `/group`.
- Database migration `008_v5_2_workspaces_fx_groups.sql`.

## Deploy
1. Back up the production PostgreSQL database.
2. Run `database/008_v5_2_workspaces_fx_groups.sql` against the production database.
3. Deploy this source to Render.
4. Confirm `DATABASE_URL`, `AUTH_SECRET` and `ENABLE_2FA` are configured in Render.
5. Log in as Super Admin and open **Staff Onboarding**.
6. Create a test staff user (for example Kelechi), copy the one-time temporary password, then test first login, password change, MFA enrollment, branch restrictions and role restrictions.
7. Open **FX Rates & Estimator**, publish a test rate, then verify the public `/fx` estimator.
8. Register a test Ajo group at `/group-signup`, then verify its isolated `/group` dashboard.

## Important production note
The FX module deliberately does not invent or scrape a settlement rate. `provider_rate` and `customer_rate` are stored separately. Connect the actual licensed payment/FX provider API when provider credentials and commercial rules are finalized. Until then, authorized finance staff publish the approved rate manually.
