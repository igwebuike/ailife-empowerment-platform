-- AIBLE v5 production migration for the EXISTING Render PostgreSQL database
-- Generated 2026-09-27
-- IMPORTANT: existing production core IDs are INTEGER. New standalone module IDs use UUID,
-- but every FK back to branches/staff_profiles/customers/loans/transactions/loan_products uses INTEGER.
-- This migration does not delete, truncate, or replace existing production data.

BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- 1. OPERATIONS / ONBOARDING
-- ============================================================

CREATE TABLE IF NOT EXISTS organizational_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  department text NOT NULL,
  role_name text NOT NULL,
  reports_to text,
  level_no integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(department, role_name)
);

CREATE TABLE IF NOT EXISTS loan_approval_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name text UNIQUE NOT NULL,
  min_amount numeric(14,2) DEFAULT 0,
  max_amount numeric(14,2),
  processor_role text NOT NULL DEFAULT 'credit_officer',
  recommender_role text NOT NULL DEFAULT 'branch_manager',
  approver_role text NOT NULL,
  disburser_role text NOT NULL DEFAULT 'branch_manager',
  finance_release_required boolean DEFAULT true,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS staff_onboarding_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id integer REFERENCES staff_profiles(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  role text NOT NULL,
  branch_id integer REFERENCES branches(id),
  email text,
  phone text,
  status text DEFAULT 'pending',
  start_date date,
  created_by integer REFERENCES staff_profiles(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS training_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_code text UNIQUE NOT NULL,
  title text NOT NULL,
  audience text NOT NULL,
  required boolean DEFAULT true,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS staff_training_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id integer REFERENCES staff_profiles(id) ON DELETE CASCADE,
  module_id uuid REFERENCES training_modules(id),
  status text DEFAULT 'not_started',
  score numeric(5,2),
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(staff_id, module_id)
);

CREATE TABLE IF NOT EXISTS client_onboarding_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id integer REFERENCES customers(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  phone text NOT NULL,
  branch_id integer REFERENCES branches(id),
  onboarding_channel text DEFAULT 'branch',
  status text DEFAULT 'started',
  assigned_staff_id integer REFERENCES staff_profiles(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS onboarding_checklist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_type text NOT NULL,
  item_code text NOT NULL,
  title text NOT NULL,
  required boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  UNIQUE(checklist_type, item_code)
);

CREATE TABLE IF NOT EXISTS onboarding_checklist_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checklist_item_id uuid REFERENCES onboarding_checklist_items(id),
  staff_case_id uuid REFERENCES staff_onboarding_cases(id) ON DELETE CASCADE,
  client_case_id uuid REFERENCES client_onboarding_cases(id) ON DELETE CASCADE,
  status text DEFAULT 'pending',
  completed_by integer REFERENCES staff_profiles(id),
  completed_at timestamptz,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_code text UNIQUE,
  name text NOT NULL,
  description text,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  assigned_to integer REFERENCES staff_profiles(id),
  branch_id integer REFERENCES branches(id),
  status text DEFAULT 'pending',
  priority text DEFAULT 'normal',
  due_date date,
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

-- ============================================================
-- 2. RISK / FRAUD / NOTIFICATIONS / BRANCH CASH / AGENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS risk_alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  severity text DEFAULT 'medium',
  alert_type text NOT NULL,
  message text NOT NULL,
  related_table text,
  related_id text,
  status text DEFAULT 'open',
  assigned_to integer REFERENCES staff_profiles(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notification_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel text NOT NULL,
  recipient text NOT NULL,
  subject text,
  message text NOT NULL,
  provider text DEFAULT 'termii',
  status text DEFAULT 'queued',
  related_table text,
  related_id text,
  attempts integer DEFAULT 0,
  last_error text,
  created_at timestamptz DEFAULT now(),
  sent_at timestamptz
);

CREATE TABLE IF NOT EXISTS branch_cash_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id integer REFERENCES branches(id),
  cash_type text NOT NULL,
  holder_staff_id integer REFERENCES staff_profiles(id),
  balance numeric(14,2) DEFAULT 0,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS agents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_code text UNIQUE DEFAULT concat('AGT-',upper(substr(encode(gen_random_bytes(5),'hex'),1,8))),
  business_name text NOT NULL,
  contact_name text NOT NULL,
  phone text NOT NULL,
  location text,
  branch_id integer REFERENCES branches(id),
  supervisor_id integer REFERENCES staff_profiles(id),
  cash_account_id uuid REFERENCES branch_cash_accounts(id),
  status text DEFAULT 'pending',
  daily_limit numeric(14,2) DEFAULT 200000,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 3. CREDIT BUREAU + INTERNAL RISK
-- ============================================================

CREATE TABLE IF NOT EXISTS credit_bureau_providers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_code text UNIQUE NOT NULL,
  provider_name text NOT NULL,
  base_url text,
  api_key_ref text,
  client_id_ref text,
  client_secret_ref text,
  environment text DEFAULT 'sandbox',
  enabled boolean DEFAULT false,
  live_checks_allowed boolean DEFAULT false,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS credit_bureau_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id integer REFERENCES customers(id),
  loan_id integer REFERENCES loans(id),
  provider_id uuid REFERENCES credit_bureau_providers(id),
  check_type text DEFAULT 'credit_report',
  status text DEFAULT 'pending',
  request_payload jsonb DEFAULT '{}'::jsonb,
  response_payload jsonb DEFAULT '{}'::jsonb,
  bureau_score numeric,
  bureau_decision text,
  error_message text,
  requested_by integer REFERENCES staff_profiles(id),
  reviewed_by integer REFERENCES staff_profiles(id),
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE IF NOT EXISTS internal_risk_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_code text UNIQUE NOT NULL,
  title text NOT NULL,
  description text,
  points integer NOT NULL DEFAULT 0,
  severity text DEFAULT 'medium',
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS internal_risk_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id integer REFERENCES customers(id),
  loan_id integer REFERENCES loans(id),
  score integer NOT NULL DEFAULT 0,
  risk_band text NOT NULL DEFAULT 'low',
  decision text NOT NULL DEFAULT 'manual_review',
  factors jsonb DEFAULT '[]'::jsonb,
  calculated_by text DEFAULT 'AILIFE_INTERNAL_RISK_ENGINE',
  calculated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS manual_credit_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id integer REFERENCES customers(id),
  loan_id integer REFERENCES loans(id),
  internal_risk_score_id uuid REFERENCES internal_risk_scores(id),
  credit_bureau_check_id uuid REFERENCES credit_bureau_checks(id),
  status text DEFAULT 'pending',
  reviewer_id integer REFERENCES staff_profiles(id),
  recommendation text,
  conditions text,
  notes text,
  created_at timestamptz DEFAULT now(),
  reviewed_at timestamptz
);

CREATE TABLE IF NOT EXISTS credit_bureau_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id integer REFERENCES staff_profiles(id),
  event_type text NOT NULL,
  entity_type text NOT NULL DEFAULT 'credit_bureau',
  entity_id text,
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 4. CREDIT SERVICES / SaaS
-- ============================================================

CREATE TABLE IF NOT EXISTS service_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_name text NOT NULL,
  client_type text NOT NULL DEFAULT 'microfinance',
  contact_name text,
  email text UNIQUE,
  phone text,
  address text,
  status text DEFAULT 'lead',
  plan_code text DEFAULT 'starter',
  kyc_status text DEFAULT 'pending',
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS customer_consents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_client_id uuid REFERENCES service_clients(id),
  customer_id integer REFERENCES customers(id),
  customer_name text NOT NULL,
  phone text,
  bvn text,
  nin text,
  consent_type text NOT NULL,
  consent_channel text DEFAULT 'digital',
  consent_text text,
  signed_at timestamptz,
  expires_at timestamptz,
  status text DEFAULT 'pending',
  evidence_url text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS credit_service_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_code text UNIQUE NOT NULL,
  product_name text NOT NULL,
  description text,
  service_type text NOT NULL,
  price_amount numeric(14,2) DEFAULT 0,
  currency text DEFAULT 'NGN',
  requires_bureau_credentials boolean DEFAULT false,
  requires_customer_consent boolean DEFAULT true,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS credit_service_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_no text UNIQUE DEFAULT concat('CSR-',upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  service_client_id uuid REFERENCES service_clients(id),
  consent_id uuid REFERENCES customer_consents(id),
  requested_by integer REFERENCES staff_profiles(id),
  request_type text NOT NULL DEFAULT 'internal_risk_report',
  customer_name text,
  customer_phone text,
  bvn text,
  nin text,
  price_amount numeric(14,2) DEFAULT 0,
  payment_status text DEFAULT 'unpaid',
  status text DEFAULT 'submitted',
  internal_score integer,
  risk_band text,
  decision text,
  report_url text,
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE IF NOT EXISTS credit_check_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_no text UNIQUE DEFAULT concat('CCO-',upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  service_request_id uuid REFERENCES credit_service_requests(id),
  service_client_id uuid REFERENCES service_clients(id),
  customer_name text,
  service_type text NOT NULL,
  amount numeric(14,2) NOT NULL DEFAULT 0,
  currency text DEFAULT 'NGN',
  status text DEFAULT 'pending',
  payment_reference text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bureau_upload_queue (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_code text DEFAULT 'creditregistry',
  upload_type text NOT NULL,
  source_table text,
  source_id text,
  payload jsonb,
  status text DEFAULT 'queued',
  upload_id text,
  transaction_id text,
  error_message text,
  created_at timestamptz DEFAULT now(),
  processed_at timestamptz
);

CREATE TABLE IF NOT EXISTS saas_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_client_id uuid REFERENCES service_clients(id),
  client_name text NOT NULL,
  plan_code text NOT NULL,
  status text DEFAULT 'trial',
  monthly_fee numeric(14,2) DEFAULT 0,
  users_allowed integer DEFAULT 5,
  branches_allowed integer DEFAULT 1,
  started_at timestamptz DEFAULT now(),
  next_billing_date date,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS api_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  service_client_id uuid REFERENCES service_clients(id),
  client_name text NOT NULL,
  environment text DEFAULT 'sandbox',
  status text DEFAULT 'disabled',
  public_key_ref text,
  secret_key_ref text,
  rate_limit_per_day integer DEFAULT 100,
  last_used_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS revenue_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  service_client_id uuid REFERENCES service_clients(id),
  customer_name text,
  amount numeric(14,2) NOT NULL DEFAULT 0,
  currency text DEFAULT 'NGN',
  status text DEFAULT 'pending',
  source_reference text,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 5. AIBLE V5 GROUPS / AJO / CONTRIBUTIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_code text UNIQUE DEFAULT concat('ORG-',upper(substr(encode(gen_random_bytes(6),'hex'),1,8))),
  name text NOT NULL,
  organization_type text NOT NULL DEFAULT 'contribution_group',
  contact_name text,
  email text,
  phone text,
  plan_code text DEFAULT 'starter',
  status text DEFAULT 'active',
  settings jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS organization_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  customer_id integer REFERENCES customers(id) ON DELETE SET NULL,
  member_no text,
  full_name text NOT NULL,
  phone text,
  email text,
  role text DEFAULT 'member',
  status text DEFAULT 'active',
  joined_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, member_no)
);

CREATE TABLE IF NOT EXISTS contribution_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  name text NOT NULL,
  contribution_type text DEFAULT 'fixed',
  amount numeric(14,2) DEFAULT 0,
  frequency text DEFAULT 'monthly',
  penalty_amount numeric(14,2) DEFAULT 0,
  starts_on date,
  ends_on date,
  status text DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS contributions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id),
  member_id uuid NOT NULL REFERENCES organization_members(id),
  plan_id uuid REFERENCES contribution_plans(id),
  amount numeric(14,2) NOT NULL CHECK(amount > 0),
  due_date date,
  paid_at timestamptz,
  channel text DEFAULT 'cash',
  provider text,
  provider_reference text,
  internal_reference text UNIQUE DEFAULT concat('CON-',upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  status text DEFAULT 'pending',
  integrity_hash text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payment_provider_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider text NOT NULL,
  event_type text NOT NULL,
  provider_reference text,
  status text DEFAULT 'received',
  payload jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 6. AUTHENTICATION + AUDIT
-- ============================================================

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  staff_id integer NOT NULL REFERENCES staff_profiles(id) ON DELETE CASCADE,
  token_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id integer REFERENCES staff_profiles(id),
  action text NOT NULL,
  entity_type text,
  entity_id text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);

-- ============================================================
-- 7. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_client_onboarding_customer ON client_onboarding_cases(customer_id);
CREATE INDEX IF NOT EXISTS idx_client_onboarding_staff ON client_onboarding_cases(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_onboarding_staff ON staff_onboarding_cases(staff_id);
CREATE INDEX IF NOT EXISTS idx_risk_alerts_status ON risk_alerts(status);
CREATE INDEX IF NOT EXISTS idx_credit_checks_customer ON credit_bureau_checks(customer_id);
CREATE INDEX IF NOT EXISTS idx_internal_scores_customer ON internal_risk_scores(customer_id);
CREATE INDEX IF NOT EXISTS idx_contributions_org_status ON contributions(organization_id,status);
CREATE INDEX IF NOT EXISTS idx_org_members_org ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_reset_token_hash ON password_reset_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_reset_staff ON password_reset_tokens(staff_id);

-- ============================================================
-- 8. SAFE CONFIGURATION SEEDS (no demo customers/staff)
-- ============================================================

INSERT INTO credit_bureau_providers
(provider_code,provider_name,base_url,environment,enabled,live_checks_allowed,notes)
VALUES
('CREDIT_REGISTRY','CreditRegistry Nigeria',NULL,'sandbox',false,false,'Awaiting approved production credentials.'),
('CRC','CRC Credit Bureau',NULL,'sandbox',false,false,'Optional second bureau connector.'),
('FIRSTCENTRAL','FirstCentral Credit Bureau',NULL,'sandbox',false,false,'Optional second bureau connector.'),
('INTERNAL','AILIFE Internal Risk Engine',NULL,'production',true,true,'Internal scoring engine.')
ON CONFLICT(provider_code) DO NOTHING;

INSERT INTO internal_risk_rules(rule_code,title,description,points,severity,active)
VALUES
('DUPLICATE_BVN','Duplicate BVN/NIN detected','Duplicate identity requires review.',35,'critical',true),
('HIGH_LOAN_AMOUNT','High loan amount','Higher exposure requires enhanced approval.',20,'high',true),
('NEW_CUSTOMER','New customer','First-time borrower requires additional review.',15,'medium',true),
('OVERDUE_HISTORY','Overdue/default history','Prior delinquency increases credit risk.',30,'high',true),
('MISSING_KYC','Incomplete KYC','Missing KYC requires manual review.',25,'high',true),
('STAFF_CONFLICT','Maker-checker conflict','Separate staff approval required.',40,'critical',true)
ON CONFLICT(rule_code) DO NOTHING;

INSERT INTO onboarding_checklist_items(checklist_type,item_code,title,required,sort_order)
VALUES
('client','CLIENT_PROFILE','Capture client biodata, phone, address, branch and business details',true,1),
('client','KYC_ID','Collect BVN/NIN or valid identification',true,2),
('client','PHOTO','Capture client photo/selfie',true,3),
('client','GUARANTOR','Capture guarantor information and form',true,4),
('client','BUSINESS_VERIFICATION','Verify business/location in the field',true,5),
('client','CONSENT','Capture data consent and loan terms acceptance',true,6),
('staff','STAFF_PROFILE','Create staff profile, role, branch, phone and email',true,1),
('staff','DOCUMENTS','Collect employment documents and ID',true,2),
('staff','ROLE_ACCESS','Assign role-based access and branch permissions',true,3),
('staff','MFA_SETUP','Enable two-factor authentication',true,4),
('staff','TRAINING','Complete required platform and governance training',true,5),
('staff','APPROVAL','Manager approves staff activation',true,6)
ON CONFLICT(checklist_type,item_code) DO NOTHING;

INSERT INTO training_modules(module_code,title,audience,required)
VALUES
('PLATFORM-BASICS','Using AILIFE Command Center for remote work and monitoring','all_staff',true),
('CLIENT-ONBOARDING','Client onboarding, KYC capture and field verification','credit_officer,branch_manager,agent',true),
('LOAN-WORKFLOW','AILIFE loan products, fees, approval workflow and disbursement policy','credit_officer,branch_manager,area_manager,program_director',true),
('COLLECTIONS','Repayments, savings collection, alerts and outstanding balance management','credit_officer,branch_manager,teller,agent',true),
('FRAUD-GOVERNANCE','Maker-checker, audit trail, fraud red flags and escalation','all_staff',true),
('REPORTING','Daily, weekly, monthly, branch and staff performance reporting','branch_manager,area_manager,program_manager,executive_director',true)
ON CONFLICT(module_code) DO NOTHING;

INSERT INTO organizations(name,organization_type,contact_name,email,plan_code,status)
SELECT 'AILIFE Empowerment','ailife','Platform Administrator','admin@ailifeempowerment.com','enterprise','active'
WHERE NOT EXISTS (SELECT 1 FROM organizations WHERE organization_type='ailife');

COMMIT;

-- Verification:
-- SELECT table_name FROM information_schema.tables
-- WHERE table_schema='public' ORDER BY table_name;
