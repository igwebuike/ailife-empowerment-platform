-- AILIFE Empowerment Banking-Grade Upgrade v3
-- Includes the 10 production gaps: double-entry ledger, maker-checker, transaction engine,
-- fraud rules, SMS/email outbox, file storage metadata, branch cash, agents, regulatory reports.
-- Run directly in Render PostgreSQL using the psql shell or a database client.

create extension if not exists pgcrypto;

-- =========================
-- 1) STAFF / ROLES / BRANCHES
-- =========================
create table if not exists branches (
  id uuid primary key default gen_random_uuid(),
  branch_code text unique not null,
  name text not null,
  address text,
  manager_name text,
  status text default 'active' check(status in ('active','inactive')),
  created_at timestamptz default now()
);

create table if not exists staff_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  full_name text not null,
  email text unique not null,
  phone text,
  role text not null check (role in ('executive_director','admin','branch_manager','loan_officer','finance_officer','compliance_officer','auditor','board_viewer','agent_supervisor','teller')),
  branch_id uuid references branches(id),
  branch text default 'Head Office',
  mfa_required boolean default true,
  password_hash text,
  totp_secret text,
  status text default 'active' check(status in ('active','suspended','inactive')),
  created_at timestamptz default now()
);

-- =========================
-- 2) CUSTOMERS / KYC / DOCUMENTS
-- =========================
create table if not exists customers (
  id uuid primary key default gen_random_uuid(),
  customer_no text unique default concat('AIL-', upper(substr(encode(gen_random_bytes(6),'hex'),1,10))),
  full_name text not null,
  phone text not null,
  email text,
  bvn text,
  nin text,
  address text,
  business_name text,
  community text,
  branch_id uuid references branches(id),
  branch text default 'Head Office',
  status text default 'pending_kyc' check (status in ('pending_kyc','verified','rejected','suspended')),
  risk_score int default 0 check(risk_score between 0 and 100),
  created_by uuid references staff_profiles(id),
  created_at timestamptz default now()
);
create unique index if not exists customers_bvn_unique on customers(bvn) where bvn is not null and bvn <> '';
create unique index if not exists customers_nin_unique on customers(nin) where nin is not null and nin <> '';

create table if not exists kyc_documents (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id) on delete cascade,
  doc_type text not null check(doc_type in ('nin','bvn_slip','passport_photo','selfie','utility_bill','guarantor_form','business_photo','other')),
  file_name text not null,
  file_url text not null,
  storage_bucket text default 'kyc-documents',
  verification_status text default 'pending' check(verification_status in ('pending','verified','rejected')),
  verified_by uuid references staff_profiles(id),
  created_at timestamptz default now()
);

-- =========================
-- 3) ACCOUNTS + DOUBLE ENTRY LEDGER
-- =========================
create table if not exists chart_of_accounts (
  id uuid primary key default gen_random_uuid(),
  account_code text unique not null,
  account_name text not null,
  account_type text not null check(account_type in ('asset','liability','income','expense','equity')),
  normal_balance text not null check(normal_balance in ('debit','credit')),
  is_system boolean default false,
  created_at timestamptz default now()
);

create table if not exists savings_accounts (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id) on delete cascade,
  account_number text unique not null,
  product_type text default 'daily_savings',
  ledger_account_id uuid references chart_of_accounts(id),
  balance numeric(14,2) default 0 check(balance >= 0),
  status text default 'active' check(status in ('active','frozen','closed')),
  created_at timestamptz default now()
);

create table if not exists ledger_journals (
  id uuid primary key default gen_random_uuid(),
  journal_no text unique default concat('JRN-', upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  description text not null,
  source_module text not null,
  source_id uuid,
  posted_by uuid references staff_profiles(id),
  status text default 'posted' check(status in ('draft','posted','reversed')),
  created_at timestamptz default now()
);

create table if not exists ledger_entries (
  id uuid primary key default gen_random_uuid(),
  journal_id uuid references ledger_journals(id) on delete cascade,
  account_id uuid references chart_of_accounts(id),
  debit numeric(14,2) default 0 check(debit >= 0),
  credit numeric(14,2) default 0 check(credit >= 0),
  created_at timestamptz default now(),
  check ((debit > 0 and credit = 0) or (credit > 0 and debit = 0))
);

create or replace view trial_balance as
select coa.account_code, coa.account_name, coa.account_type,
       coalesce(sum(le.debit),0) debit,
       coalesce(sum(le.credit),0) credit,
       case when coa.normal_balance='debit' then coalesce(sum(le.debit-le.credit),0)
            else coalesce(sum(le.credit-le.debit),0) end balance
from chart_of_accounts coa
left join ledger_entries le on le.account_id=coa.id
left join ledger_journals lj on lj.id=le.journal_id and lj.status='posted'
group by coa.id, coa.account_code, coa.account_name, coa.account_type, coa.normal_balance;

-- =========================
-- 4) LOANS / APPROVALS / MAKER-CHECKER
-- =========================
create table if not exists loans (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id) on delete set null,
  customer_name text,
  principal numeric(14,2) not null check(principal > 0),
  outstanding_balance numeric(14,2) default 0,
  interest_rate numeric(5,2) default 0,
  term_weeks int default 23,
  moratorium_weeks int default 2,
  status text default 'draft' check (status in ('draft','submitted','approved','disbursed','rejected','closed','defaulted')),
  due_date date,
  created_by uuid references staff_profiles(id),
  approved_by uuid references staff_profiles(id),
  disbursed_by uuid references staff_profiles(id),
  created_at timestamptz default now()
);

create table if not exists approval_workflows (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null check(entity_type in ('loan','transaction','withdrawal','kyc','cash_transfer')),
  entity_id uuid not null,
  requested_by uuid references staff_profiles(id),
  first_approved_by uuid references staff_profiles(id),
  second_approved_by uuid references staff_profiles(id),
  finance_released_by uuid references staff_profiles(id),
  status text default 'pending_manager' check(status in ('pending_manager','pending_compliance','pending_finance','approved','rejected','released')),
  rejection_reason text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- =========================
-- 5) TRANSACTION ENGINE
-- =========================
create table if not exists transactions (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id) on delete set null,
  savings_account_id uuid references savings_accounts(id),
  loan_id uuid references loans(id),
  customer_name text,
  type text not null check (type in ('deposit','withdrawal','loan_disbursement','loan_repayment','fee','adjustment','reversal')),
  amount numeric(14,2) not null check (amount > 0),
  channel text default 'cash' check (channel in ('cash','bank_transfer','pos','mobile_money','ussd','agent','manual')),
  status text default 'pending' check (status in ('pending','approved','rejected','reversed')),
  maker_id uuid references staff_profiles(id),
  checker_id uuid references staff_profiles(id),
  journal_id uuid references ledger_journals(id),
  reference text unique default concat('TXN-',upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  reversal_of uuid references transactions(id),
  created_at timestamptz default now(),
  approved_at timestamptz
);

-- Prevent same user from making and checking the same transaction.
create or replace function enforce_maker_checker() returns trigger as $$
begin
  if new.status='approved' and (new.checker_id is null or new.maker_id is null or new.checker_id = new.maker_id) then
    raise exception 'Maker-checker violation: checker must be different from maker';
  end if;
  return new;
end; $$ language plpgsql;
drop trigger if exists trg_enforce_maker_checker on transactions;
create trigger trg_enforce_maker_checker before insert or update on transactions for each row execute function enforce_maker_checker();

-- Atomic transaction posting with row lock, balance update, and double-entry journal.
create or replace function approve_transaction(p_transaction_id uuid, p_checker_id uuid) returns uuid as $$
declare
  t transactions%rowtype;
  acct savings_accounts%rowtype;
  cash_acct uuid;
  cust_liability uuid;
  loan_asset uuid;
  fee_income uuid;
  j uuid;
begin
  select * into t from transactions where id=p_transaction_id for update;
  if not found then raise exception 'Transaction not found'; end if;
  if t.status <> 'pending' then raise exception 'Only pending transactions can be approved'; end if;
  if t.maker_id = p_checker_id then raise exception 'Checker cannot be maker'; end if;

  select * into acct from savings_accounts where id=t.savings_account_id for update;
  if t.type in ('withdrawal') and (acct.id is null or acct.balance < t.amount) then
    raise exception 'Insufficient balance or missing account';
  end if;

  select id into cash_acct from chart_of_accounts where account_code='1000';
  select id into cust_liability from chart_of_accounts where account_code='2000';
  select id into loan_asset from chart_of_accounts where account_code='1100';
  select id into fee_income from chart_of_accounts where account_code='4000';

  insert into ledger_journals(description, source_module, source_id, posted_by)
  values (concat('Approved ',t.type,' ',t.reference),'transactions',t.id,p_checker_id) returning id into j;

  if t.type='deposit' then
    update savings_accounts set balance=balance+t.amount where id=t.savings_account_id;
    insert into ledger_entries(journal_id,account_id,debit) values(j,cash_acct,t.amount);
    insert into ledger_entries(journal_id,account_id,credit) values(j,cust_liability,t.amount);
  elsif t.type='withdrawal' then
    update savings_accounts set balance=balance-t.amount where id=t.savings_account_id;
    insert into ledger_entries(journal_id,account_id,debit) values(j,cust_liability,t.amount);
    insert into ledger_entries(journal_id,account_id,credit) values(j,cash_acct,t.amount);
  elsif t.type='loan_disbursement' then
    update loans set outstanding_balance=outstanding_balance+t.amount, status='disbursed', disbursed_by=p_checker_id where id=t.loan_id;
    insert into ledger_entries(journal_id,account_id,debit) values(j,loan_asset,t.amount);
    insert into ledger_entries(journal_id,account_id,credit) values(j,cash_acct,t.amount);
  elsif t.type='loan_repayment' then
    update loans set outstanding_balance=greatest(outstanding_balance-t.amount,0) where id=t.loan_id;
    insert into ledger_entries(journal_id,account_id,debit) values(j,cash_acct,t.amount);
    insert into ledger_entries(journal_id,account_id,credit) values(j,loan_asset,t.amount);
  elsif t.type='fee' then
    insert into ledger_entries(journal_id,account_id,debit) values(j,cash_acct,t.amount);
    insert into ledger_entries(journal_id,account_id,credit) values(j,fee_income,t.amount);
  end if;

  update transactions set status='approved', checker_id=p_checker_id, journal_id=j, approved_at=now() where id=p_transaction_id;
  return j;
end; $$ language plpgsql;

create or replace function reverse_transaction(p_transaction_id uuid, p_maker_id uuid, p_reason text) returns uuid as $$
declare
  original transactions%rowtype;
  rev uuid;
begin
  select * into original from transactions where id=p_transaction_id for update;
  if not found then raise exception 'Original transaction not found'; end if;
  if original.status <> 'approved' then raise exception 'Only approved transactions can be reversed'; end if;
  insert into transactions(customer_id,savings_account_id,loan_id,customer_name,type,amount,channel,status,maker_id,reversal_of)
  values(original.customer_id,original.savings_account_id,original.loan_id,original.customer_name,'reversal',original.amount,original.channel,'pending',p_maker_id,original.id)
  returning id into rev;
  insert into risk_alerts(severity,alert_type,message,related_table,related_id)
  values('high','reversal_requested',concat('Reversal requested: ',p_reason),'transactions',rev);
  return rev;
end; $$ language plpgsql;

-- =========================
-- 6) FRAUD ENGINE / RULES
-- =========================
create table if not exists risk_alerts (
  id uuid primary key default gen_random_uuid(),
  severity text default 'medium' check (severity in ('low','medium','high','critical')),
  alert_type text not null,
  message text not null,
  related_table text,
  related_id uuid,
  status text default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  assigned_to uuid references staff_profiles(id),
  created_at timestamptz default now()
);

create table if not exists fraud_rules (
  id uuid primary key default gen_random_uuid(),
  rule_code text unique not null,
  description text not null,
  threshold_amount numeric(14,2),
  is_active boolean default true,
  created_at timestamptz default now()
);

create or replace function fraud_scan_transaction() returns trigger as $$
declare
  velocity_count int;
begin
  if new.type='withdrawal' and new.amount >= 500000 then
    insert into risk_alerts(severity, alert_type, message, related_table, related_id)
    values ('high','large_withdrawal', concat('Large withdrawal requires review: ₦',new.amount,' ref ',new.reference), 'transactions', new.id);
  end if;

  select count(*) into velocity_count from transactions
  where customer_id=new.customer_id and created_at > now() - interval '10 minutes';
  if velocity_count >= 3 then
    insert into risk_alerts(severity, alert_type, message, related_table, related_id)
    values ('high','velocity_rule', concat('Multiple transactions within 10 minutes for ',coalesce(new.customer_name,'customer')), 'transactions', new.id);
  end if;

  if new.maker_id is not null and new.checker_id is not null and new.maker_id=new.checker_id then
    insert into risk_alerts(severity, alert_type, message, related_table, related_id)
    values ('critical','insider_maker_checker_violation', 'Maker and checker are same user', 'transactions', new.id);
  end if;
  return new;
end; $$ language plpgsql;
drop trigger if exists trg_fraud_scan_transaction on transactions;
create trigger trg_fraud_scan_transaction after insert or update on transactions for each row execute function fraud_scan_transaction();

create or replace function fraud_scan_customer() returns trigger as $$
begin
  if exists(select 1 from customers where id<>new.id and bvn is not null and bvn<>'' and bvn=new.bvn) then
    insert into risk_alerts(severity, alert_type, message, related_table, related_id)
    values ('critical','duplicate_bvn', concat('Duplicate BVN detected for ',new.full_name), 'customers', new.id);
  end if;
  if exists(select 1 from customers where id<>new.id and nin is not null and nin<>'' and nin=new.nin) then
    insert into risk_alerts(severity, alert_type, message, related_table, related_id)
    values ('critical','duplicate_nin', concat('Duplicate NIN detected for ',new.full_name), 'customers', new.id);
  end if;
  return new;
end; $$ language plpgsql;
drop trigger if exists trg_fraud_scan_customer on customers;
create trigger trg_fraud_scan_customer after insert or update on customers for each row execute function fraud_scan_customer();

-- =========================
-- 7) SMS / EMAIL / NOTIFICATION OUTBOX
-- =========================
create table if not exists notification_outbox (
  id uuid primary key default gen_random_uuid(),
  channel text not null check(channel in ('sms','email','whatsapp','push')),
  recipient text not null,
  subject text,
  message text not null,
  provider text default 'termii',
  status text default 'queued' check(status in ('queued','sent','failed','cancelled')),
  related_table text,
  related_id uuid,
  attempts int default 0,
  last_error text,
  created_at timestamptz default now(),
  sent_at timestamptz
);

create or replace function queue_customer_transaction_notice() returns trigger as $$
declare c customers%rowtype;
begin
  if new.customer_id is not null and new.status='approved' then
    select * into c from customers where id=new.customer_id;
    if c.phone is not null then
      insert into notification_outbox(channel,recipient,message,related_table,related_id)
      values('sms',c.phone,concat('AILIFE Alert: ',upper(new.type),' of NGN ',new.amount,' was approved. Ref: ',new.reference),'transactions',new.id);
    end if;
    if c.email is not null then
      insert into notification_outbox(channel,recipient,subject,message,provider,related_table,related_id)
      values('email',c.email,'AILIFE transaction alert',concat('Your ',new.type,' of NGN ',new.amount,' has been approved. Ref: ',new.reference),'resend','transactions',new.id);
    end if;
  end if;
  return new;
end; $$ language plpgsql;
drop trigger if exists trg_queue_customer_transaction_notice on transactions;
create trigger trg_queue_customer_transaction_notice after update on transactions for each row execute function queue_customer_transaction_notice();

-- =========================
-- 8) BRANCH CASH MANAGEMENT
-- =========================
create table if not exists branch_cash_accounts (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid references branches(id),
  cash_type text not null check(cash_type in ('vault_cash','teller_cash','field_cash','agent_cash')),
  holder_staff_id uuid references staff_profiles(id),
  balance numeric(14,2) default 0 check(balance >= 0),
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists cash_movements (
  id uuid primary key default gen_random_uuid(),
  from_cash_account_id uuid references branch_cash_accounts(id),
  to_cash_account_id uuid references branch_cash_accounts(id),
  amount numeric(14,2) not null check(amount > 0),
  reason text not null,
  maker_id uuid references staff_profiles(id),
  checker_id uuid references staff_profiles(id),
  status text default 'pending' check(status in ('pending','approved','rejected','reversed')),
  created_at timestamptz default now(),
  approved_at timestamptz
);

-- =========================
-- 9) AGENT BANKING
-- =========================
create table if not exists agents (
  id uuid primary key default gen_random_uuid(),
  agent_code text unique default concat('AGT-',upper(substr(encode(gen_random_bytes(5),'hex'),1,8))),
  business_name text not null,
  contact_name text not null,
  phone text not null,
  location text,
  branch_id uuid references branches(id),
  supervisor_id uuid references staff_profiles(id),
  cash_account_id uuid references branch_cash_accounts(id),
  status text default 'pending' check(status in ('pending','active','suspended','terminated')),
  daily_limit numeric(14,2) default 200000,
  created_at timestamptz default now()
);

create table if not exists agent_activity_logs (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid references agents(id),
  activity_type text not null check(activity_type in ('customer_onboarding','deposit_collection','loan_repayment_collection','cash_float_request','cash_return')),
  amount numeric(14,2),
  customer_id uuid references customers(id),
  transaction_id uuid references transactions(id),
  notes text,
  created_at timestamptz default now()
);

-- =========================
-- 10) REGULATORY / MANAGEMENT REPORTING
-- =========================
create or replace view daily_collection_report as
select date(t.created_at) report_date, coalesce(c.branch,'Head Office') branch, t.type, t.status, count(*) transaction_count, sum(t.amount) total_amount
from transactions t
left join customers c on c.id=t.customer_id
group by date(t.created_at), coalesce(c.branch,'Head Office'), t.type, t.status;

create or replace view loan_aging_report as
select l.id, coalesce(c.full_name,l.customer_name) customer_name, l.principal, l.outstanding_balance, l.due_date, l.status,
       greatest((current_date - l.due_date),0) days_past_due,
       case when l.due_date is null then 'not_due'
            when current_date <= l.due_date then 'current'
            when current_date - l.due_date between 1 and 30 then '1-30'
            when current_date - l.due_date between 31 and 60 then '31-60'
            when current_date - l.due_date between 61 and 90 then '61-90'
            else '90+' end aging_bucket
from loans l left join customers c on c.id=l.customer_id;

create or replace view portfolio_at_risk_report as
select aging_bucket, count(*) loan_count, coalesce(sum(outstanding_balance),0) outstanding,
       case when (select sum(outstanding_balance) from loans where status in ('disbursed','defaulted')) > 0
            then round(100 * coalesce(sum(outstanding_balance),0) / (select sum(outstanding_balance) from loans where status in ('disbursed','defaulted')),2)
            else 0 end par_percent
from loan_aging_report
where status in ('disbursed','defaulted')
group by aging_bucket;

create or replace view branch_performance_report as
select b.name branch_name,
       count(distinct c.id) customers,
       count(distinct l.id) loans,
       coalesce(sum(case when t.type='deposit' and t.status='approved' then t.amount else 0 end),0) deposits,
       coalesce(sum(case when t.type='withdrawal' and t.status='approved' then t.amount else 0 end),0) withdrawals,
       coalesce(sum(case when t.type='loan_repayment' and t.status='approved' then t.amount else 0 end),0) repayments
from branches b
left join customers c on c.branch_id=b.id
left join loans l on l.customer_id=c.id
left join transactions t on t.customer_id=c.id
group by b.id,b.name;

create or replace view board_summary_report as
select
  (select count(*) from customers) total_customers,
  (select count(*) from customers where status='verified') verified_customers,
  (select coalesce(sum(balance),0) from savings_accounts) total_savings_balance,
  (select coalesce(sum(outstanding_balance),0) from loans where status in ('disbursed','defaulted')) loan_portfolio,
  (select count(*) from risk_alerts where status='open') open_alerts,
  (select coalesce(sum(amount),0) from transactions where status='approved' and type='deposit' and created_at::date=current_date) today_deposits,
  (select coalesce(sum(amount),0) from transactions where status='approved' and type='withdrawal' and created_at::date=current_date) today_withdrawals;

-- =========================
-- AUDIT LOGS + GOVERNANCE
-- =========================
create table if not exists audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references staff_profiles(id),
  action text not null,
  entity_table text,
  entity_id uuid,
  before_data jsonb,
  after_data jsonb,
  ip_address text,
  user_agent text,
  created_at timestamptz default now()
);

create table if not exists governance_policies (
  id uuid primary key default gen_random_uuid(),
  policy_name text unique not null,
  policy_value text not null,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- Seed governance + chart of accounts + demo branch
insert into branches(branch_code,name,address,manager_name) values ('HQ','Head Office','AILIFE Head Office','Executive Director') on conflict(branch_code) do nothing;

insert into chart_of_accounts(account_code,account_name,account_type,normal_balance,is_system) values
('1000','Cash and Bank','asset','debit',true),
('1100','Loans Receivable','asset','debit',true),
('1200','KYC/Operations Receivables','asset','debit',true),
('2000','Customer Savings Liability','liability','credit',true),
('3000','Institutional Equity','equity','credit',true),
('4000','Fee and Service Charge Income','income','credit',true),
('5000','Operating Expenses','expense','debit',true)
on conflict(account_code) do nothing;

insert into governance_policies(policy_name,policy_value) values
('maker_checker_required','true'),
('mandatory_staff_2fa','true'),
('large_withdrawal_review_threshold','500000'),
('duplicate_bvn_block','true'),
('loan_approval_same_officer_block','true'),
('transaction_velocity_rule','3 transactions in 10 minutes'),
('branch_cash_dual_control','true'),
('document_verification_required','true')
on conflict(policy_name) do nothing;

insert into fraud_rules(rule_code,description,threshold_amount) values
('LARGE_WITHDRAWAL','Withdrawal at or above review threshold',500000),
('VELOCITY_10_MIN','Three or more transactions in 10 minutes',null),
('DUPLICATE_BVN','Same BVN used by more than one customer',null),
('MAKER_CHECKER','Maker cannot approve own transaction',null),
('SAME_OFFICER_LOAN','Loan creator cannot be final approver/disburser',null)
on conflict(rule_code) do nothing;

-- Optional demo data
insert into staff_profiles(full_name,email,role,branch) values
('AILIFE Administrator','admin@ailifeempowerment.com','admin','Head Office'),
('Finance Officer','finance@ailifeempowerment.com','finance_officer','Head Office'),
('Compliance Officer','compliance@ailifeempowerment.com','compliance_officer','Head Office')
on conflict(email) do nothing;

insert into customers(full_name, phone, email, community, status, business_name, branch) values
('Demo Customer Ada Okafor','08000000001','ada@example.com','Umuahia','verified','Ada Food Store','Head Office') on conflict do nothing;

insert into savings_accounts(customer_id,account_number,balance,product_type)
select id,'AIL10000001',25000,'daily_savings' from customers where phone='08000000001'
on conflict(account_number) do nothing;

insert into loans(customer_id,customer_name,principal,outstanding_balance,interest_rate,status,due_date)
select id,full_name,70000,70000,5.0,'disbursed',current_date + interval '23 weeks' from customers where phone='08000000001'
on conflict do nothing;

-- Render PostgreSQL uses application-level authentication and role controls.
-- Supabase/RLS policies intentionally removed.

-- =========================
-- RENDER POSTGRES ADMIN SEED
-- =========================
-- Default password is: ChangeMe123!
-- Replace this password immediately after deployment.
-- Hash generated using PBKDF2-SHA256 with 100000 iterations.
insert into staff_profiles(full_name,email,phone,role,branch,mfa_required,status,password_hash)
values ('AILIFE Super Admin','admin@ailifeempowerment.com','','admin','Head Office',false,'active','a55b1fd8d8992ecf3cc32f4d90445d67:8f0625f7e8760a9ec5f20a0b44377d0cce4a04de276b87980bfb061aab25a7f1')
on conflict (email) do nothing;

-- seed_admin_staff

-- =========================
-- 11) AILIFE-SPECIFIC CONFIGURATION: BRANCHES, LOAN PRODUCTS, ONBOARDING & TRAINING
-- =========================

alter table branches drop constraint if exists branches_status_check;
alter table branches add constraint branches_status_check check(status in ('active','inactive','suspended','closed'));
alter table branches add column if not exists state text;
alter table branches add column if not exists area text;

alter table staff_profiles drop constraint if exists staff_profiles_role_check;
alter table staff_profiles add constraint staff_profiles_role_check check (role in (
  'board_trustee','governing_council','executive_director','program_director','program_manager','area_manager','branch_manager','credit_officer','accountant','program_officer','secretary','receptionist','cleaner','security','admin','finance_officer','compliance_officer','auditor','board_viewer','agent_supervisor','teller'
));

create table if not exists organizational_units (
  id uuid primary key default gen_random_uuid(),
  department text not null check(department in ('operations','administration','governance')),
  role_name text not null,
  reports_to text,
  level_no int not null,
  created_at timestamptz default now(),
  unique(department, role_name)
);

create table if not exists loan_products (
  id uuid primary key default gen_random_uuid(),
  product_code text unique not null,
  product_name text not null,
  min_amount numeric(14,2) not null,
  max_amount numeric(14,2),
  tenor_min_days int,
  tenor_max_days int,
  tenor_min_weeks int,
  tenor_max_weeks int,
  tenor_min_months int,
  tenor_max_months int,
  interest_rate numeric(5,2) not null,
  interest_method text not null check(interest_method in ('flat','flat_monthly')),
  risk_premium_rate numeric(5,2) default 2.00,
  management_fee_rate numeric(5,2) default 1.00,
  processing_fee_rate numeric(5,2) default 1.00,
  default_penalty_rate numeric(5,2) default 5.00,
  status text default 'active' check(status in ('active','inactive')),
  created_at timestamptz default now()
);

alter table loans add column if not exists product_id uuid references loan_products(id);
alter table loans add column if not exists product_code text;
alter table loans add column if not exists risk_premium_amount numeric(14,2) default 0;
alter table loans add column if not exists management_fee_amount numeric(14,2) default 0;
alter table loans add column if not exists processing_fee_amount numeric(14,2) default 0;
alter table loans add column if not exists penalty_amount numeric(14,2) default 0;
alter table loans add column if not exists recommended_by uuid references staff_profiles(id);
alter table loans add column if not exists area_approved_by uuid references staff_profiles(id);
alter table loans add column if not exists program_director_approved_by uuid references staff_profiles(id);

create table if not exists loan_approval_rules (
  id uuid primary key default gen_random_uuid(),
  rule_name text unique not null,
  min_amount numeric(14,2) default 0,
  max_amount numeric(14,2),
  processor_role text not null default 'credit_officer',
  recommender_role text not null default 'branch_manager',
  approver_role text not null,
  disburser_role text not null default 'branch_manager',
  finance_release_required boolean default true,
  status text default 'active' check(status in ('active','inactive')),
  created_at timestamptz default now()
);

create table if not exists staff_onboarding_cases (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references staff_profiles(id) on delete cascade,
  full_name text not null,
  role text not null,
  branch_id uuid references branches(id),
  email text,
  phone text,
  status text default 'pending' check(status in ('pending','documents_pending','training','active','rejected','terminated')),
  start_date date,
  created_by uuid references staff_profiles(id),
  created_at timestamptz default now()
);

create table if not exists training_modules (
  id uuid primary key default gen_random_uuid(),
  module_code text unique not null,
  title text not null,
  audience text not null,
  required boolean default true,
  status text default 'active' check(status in ('active','inactive')),
  created_at timestamptz default now()
);

create table if not exists staff_training_records (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references staff_profiles(id) on delete cascade,
  module_id uuid references training_modules(id),
  status text default 'not_started' check(status in ('not_started','in_progress','completed','failed','waived')),
  score numeric(5,2),
  completed_at timestamptz,
  created_at timestamptz default now(),
  unique(staff_id, module_id)
);

create table if not exists client_onboarding_cases (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id) on delete cascade,
  full_name text not null,
  phone text not null,
  branch_id uuid references branches(id),
  onboarding_channel text default 'branch' check(onboarding_channel in ('branch','field','agent','online','phone')),
  status text default 'started' check(status in ('started','kyc_pending','guarantor_pending','verification','approved','rejected')),
  assigned_staff_id uuid references staff_profiles(id),
  created_at timestamptz default now()
);

create table if not exists onboarding_checklist_items (
  id uuid primary key default gen_random_uuid(),
  checklist_type text not null check(checklist_type in ('staff','client')),
  item_code text not null,
  title text not null,
  required boolean default true,
  sort_order int default 0,
  created_at timestamptz default now(),
  unique(checklist_type,item_code)
);

create table if not exists onboarding_checklist_progress (
  id uuid primary key default gen_random_uuid(),
  checklist_item_id uuid references onboarding_checklist_items(id),
  staff_case_id uuid references staff_onboarding_cases(id) on delete cascade,
  client_case_id uuid references client_onboarding_cases(id) on delete cascade,
  status text default 'pending' check(status in ('pending','completed','rejected','not_applicable')),
  completed_by uuid references staff_profiles(id),
  completed_at timestamptz,
  notes text,
  created_at timestamptz default now(),
  check ((staff_case_id is not null and client_case_id is null) or (staff_case_id is null and client_case_id is not null))
);

-- Auto-calculate AILIFE fees on loan insert/update when product exists.
create or replace function calculate_ailife_loan_fees() returns trigger as $$
declare p loan_products%rowtype;
begin
  if new.product_id is not null then
    select * into p from loan_products where id=new.product_id;
    new.product_code := p.product_code;
    new.interest_rate := p.interest_rate;
    new.risk_premium_amount := round(new.principal * p.risk_premium_rate / 100, 2);
    new.management_fee_amount := round(new.principal * p.management_fee_rate / 100, 2);
    new.processing_fee_amount := round(new.principal * p.processing_fee_rate / 100, 2);
  end if;
  return new;
end; $$ language plpgsql;
drop trigger if exists trg_calculate_ailife_loan_fees on loans;
create trigger trg_calculate_ailife_loan_fees before insert or update on loans for each row execute function calculate_ailife_loan_fees();

create or replace view staff_portfolio_report as
select sp.id staff_id, sp.full_name, sp.role, coalesce(b.name, sp.branch) branch_name,
       count(distinct c.id) clients_onboarded,
       count(distinct l.id) loans_created,
       coalesce(sum(l.principal),0) total_principal,
       coalesce(sum(l.outstanding_balance),0) outstanding_portfolio,
       coalesce(sum(case when t.type='loan_repayment' and t.status='approved' then t.amount else 0 end),0) repayments_collected,
       coalesce(sum(case when t.type='deposit' and t.status='approved' then t.amount else 0 end),0) savings_collected
from staff_profiles sp
left join branches b on b.id=sp.branch_id
left join customers c on c.created_by=sp.id
left join loans l on l.created_by=sp.id
left join transactions t on t.maker_id=sp.id
group by sp.id, sp.full_name, sp.role, b.name, sp.branch;

create or replace view onboarding_status_report as
select 'staff' record_type, status, count(*) record_count from staff_onboarding_cases group by status
union all
select 'client' record_type, status, count(*) record_count from client_onboarding_cases group by status;

-- Replace daily collection report with branch-aware version.
drop view if exists daily_collection_report;
create or replace view daily_collection_report as
select date(t.created_at) report_date, coalesce(b.name,c.branch,'Unassigned') branch, t.type, t.status,
       count(*) transaction_count, coalesce(sum(t.amount),0) total_amount
from transactions t
left join customers c on c.id=t.customer_id
left join branches b on b.id=c.branch_id
group by date(t.created_at), coalesce(b.name,c.branch,'Unassigned'), t.type, t.status;

-- Seed AILIFE branches.
insert into branches(branch_code,name,state,area,address,status) values
('HQ','Head Office Branch',null,'Head Office','Head Office','active'),
('EDE','Ede Branch','Osun','Osun State Branches','Ede, Osun State','active'),
('OSOGBO','Osogbo Branch','Osun','Osun State Branches','Osogbo, Osun State','active'),
('OWODE','Owode Branch','Osun','Osun State Branches','Owode, Osun State','active'),
('IBADAN1','Ibadan 1','Oyo','Ibadan Branches','Ibadan, Oyo State','active'),
('IBADAN2','Ibadan 2','Oyo','Ibadan Branches','Ibadan, Oyo State','active'),
('RUMUDARA','Rumudara Branch','Rivers','Port Harcourt Branches','Rumudara, Port Harcourt','active'),
('RUMUKURUSHI','Rumukurushi Branch','Rivers','Port Harcourt Branches','Rumukurushi, Port Harcourt','inactive'),
('ENEKA','Eneka Branch','Rivers','Port Harcourt Branches','Eneka, Port Harcourt','inactive')
on conflict(branch_code) do update set name=excluded.name,state=excluded.state,area=excluded.area,address=excluded.address,status=excluded.status;

-- Seed organizational structure.
insert into organizational_units(department,role_name,reports_to,level_no) values
('governance','Board of Trustees',null,1),
('governance','Governing Council','Board of Trustees',2),
('governance','Executive Director','Governing Council',3),
('operations','Executive Director',null,1),
('operations','Program Director','Executive Director',2),
('operations','Program Manager','Program Director',3),
('operations','Area Manager','Program Manager',4),
('operations','Branch Manager','Area Manager',5),
('operations','Credit Officer','Branch Manager',6),
('administration','Executive Director',null,1),
('administration','Program Director','Executive Director',2),
('administration','Accountant','Program Director',3),
('administration','Program Officer','Program Director',3),
('administration','Secretary / Receptionist','Program Director',4),
('administration','Cleaners and Securities','Secretary / Receptionist',5)
on conflict(department,role_name) do update set reports_to=excluded.reports_to, level_no=excluded.level_no;

-- Seed AILIFE loan products.
insert into loan_products(product_code,product_name,min_amount,max_amount,tenor_min_days,tenor_max_days,tenor_min_weeks,tenor_max_weeks,tenor_min_months,tenor_max_months,interest_rate,interest_method,risk_premium_rate,management_fee_rate,processing_fee_rate,default_penalty_rate) values
('DL','Daily Loan',20000,250000,25,30,null,null,null,null,20,'flat',2,1,1,5),
('WL','Weekly Loan',50000,500000,null,null,12,16,null,null,20,'flat',2,1,1,5),
('ML','Monthly Loan',200000,null,null,null,null,null,3,6,10,'flat_monthly',2,1,1,5)
on conflict(product_code) do update set product_name=excluded.product_name,min_amount=excluded.min_amount,max_amount=excluded.max_amount,interest_rate=excluded.interest_rate,interest_method=excluded.interest_method;

-- Seed approval rules based on owner-provided policy.
insert into loan_approval_rules(rule_name,min_amount,max_amount,processor_role,recommender_role,approver_role,disburser_role,finance_release_required) values
('Loans up to 400k',0,400000,'credit_officer','branch_manager','area_manager','branch_manager',true),
('Loans above 400k',400000.01,null,'credit_officer','branch_manager','program_director','branch_manager',true)
on conflict(rule_name) do update set max_amount=excluded.max_amount,approver_role=excluded.approver_role,finance_release_required=excluded.finance_release_required;

-- Seed onboarding and training checklists.
insert into onboarding_checklist_items(checklist_type,item_code,title,required,sort_order) values
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
on conflict(checklist_type,item_code) do update set title=excluded.title, required=excluded.required, sort_order=excluded.sort_order;

insert into training_modules(module_code,title,audience,required) values
('PLATFORM-BASICS','Using AILIFE Command Center for remote work and monitoring','all_staff',true),
('CLIENT-ONBOARDING','Client onboarding, KYC capture and field verification','credit_officer,branch_manager,agent',true),
('LOAN-WORKFLOW','AILIFE loan products, fees, approval workflow and disbursement policy','credit_officer,branch_manager,area_manager,program_director',true),
('COLLECTIONS','Repayments, savings collection, alerts and outstanding balance management','credit_officer,branch_manager,teller,agent',true),
('FRAUD-GOVERNANCE','Maker-checker, audit trail, fraud red flags and escalation','all_staff',true),
('REPORTING','Daily, weekly, monthly, branch and staff performance reporting','branch_manager,area_manager,program_manager,executive_director',true)
on conflict(module_code) do update set title=excluded.title,audience=excluded.audience,required=excluded.required;

insert into governance_policies(policy_name,policy_value) values
('ailife_active_branches','Head Office, Ede, Osogbo, Owode, Ibadan 1, Ibadan 2, Rumudara'),
('ailife_inactive_branches','Rumukurushi, Eneka'),
('ailife_loan_fee_total','4% upfront charges: 2% risk premium, 1% management fee, 1% processing/bank charge'),
('ailife_default_penalty','5% flat monthly on overdue amount'),
('ailife_approval_rule','Credit Officer processes, Branch Manager recommends, Area Manager approves 0-400k, Program Director approves above 400k, Branch Manager disburses'),
('staff_onboarding_required','true'),
('client_onboarding_checklist_required','true'),
('staff_training_required_before_activation','true')
on conflict(policy_name) do update set policy_value=excluded.policy_value;


-- =========================
-- 20) CREDIT BUREAU READY MODULE — AILIFE v3.3
-- No live bureau call is required until CreditRegistry/CRC/FirstCentral credentials are issued.
-- This lets AILIFE deploy now, run internal scoring/manual reviews, and later activate API keys.
-- =========================

create table if not exists credit_bureau_providers (
  id uuid primary key default gen_random_uuid(),
  provider_code text unique not null,
  provider_name text not null,
  base_url text,
  api_key_ref text,
  client_id_ref text,
  client_secret_ref text,
  environment text default 'sandbox' check(environment in ('sandbox','production')),
  enabled boolean default false,
  live_checks_allowed boolean default false,
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists credit_bureau_checks (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id),
  loan_id uuid references loans(id),
  provider_id uuid references credit_bureau_providers(id),
  check_type text default 'credit_report' check(check_type in ('credit_report','identity_match','affordability','watchlist','mock')),
  status text default 'pending' check(status in ('pending','not_configured','manual_required','completed','failed')),
  request_payload jsonb default '{}'::jsonb,
  response_payload jsonb default '{}'::jsonb,
  bureau_score numeric,
  bureau_decision text check(bureau_decision in ('approve','review','decline') or bureau_decision is null),
  error_message text,
  requested_by uuid references staff_profiles(id),
  reviewed_by uuid references staff_profiles(id),
  created_at timestamptz default now(),
  completed_at timestamptz
);

create table if not exists internal_risk_rules (
  id uuid primary key default gen_random_uuid(),
  rule_code text unique not null,
  title text not null,
  description text,
  points int not null default 0,
  severity text default 'medium' check(severity in ('low','medium','high','critical')),
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists internal_risk_scores (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id),
  loan_id uuid references loans(id),
  score int not null default 0 check(score between 0 and 100),
  risk_band text not null default 'low' check(risk_band in ('low','medium','high','critical')),
  decision text not null default 'manual_review' check(decision in ('eligible','manual_review','decline')),
  factors jsonb default '[]'::jsonb,
  calculated_by text default 'AILIFE_INTERNAL_RISK_ENGINE',
  calculated_at timestamptz default now(),
  created_at timestamptz default now()
);

create table if not exists manual_credit_reviews (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references customers(id),
  loan_id uuid references loans(id),
  internal_risk_score_id uuid references internal_risk_scores(id),
  credit_bureau_check_id uuid references credit_bureau_checks(id),
  status text default 'pending' check(status in ('pending','in_review','approved','rejected','escalated')),
  reviewer_id uuid references staff_profiles(id),
  recommendation text check(recommendation in ('approve','approve_with_conditions','decline','escalate') or recommendation is null),
  conditions text,
  notes text,
  created_at timestamptz default now(),
  reviewed_at timestamptz
);

create table if not exists credit_bureau_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references staff_profiles(id),
  event_type text not null,
  entity_type text not null default 'credit_bureau',
  entity_id uuid,
  details jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- Configuration seeds: disabled until AILIFE completes provider onboarding and receives credentials.
insert into credit_bureau_providers(provider_code,provider_name,base_url,environment,enabled,live_checks_allowed,notes) values
('CREDIT_REGISTRY','CreditRegistry Nigeria',null,'sandbox',false,false,'Enter endpoint and credentials after CreditRegistry approval.'),
('CRC','CRC Credit Bureau',null,'sandbox',false,false,'Optional second bureau connector.'),
('FIRSTCENTRAL','FirstCentral Credit Bureau',null,'sandbox',false,false,'Optional second bureau connector.'),
('INTERNAL','AILIFE Internal Risk Engine',null,'production',true,true,'Always available; used before bureau credentials are issued.')
on conflict(provider_code) do update set provider_name=excluded.provider_name, notes=excluded.notes;

insert into internal_risk_rules(rule_code,title,description,points,severity,active) values
('DUPLICATE_BVN','Duplicate BVN/NIN detected','Customer BVN or NIN already exists on another customer profile.',35,'critical',true),
('HIGH_LOAN_AMOUNT','Requested amount is high for product or customer history','Loan amount requires higher approval and manual affordability review.',20,'high',true),
('NEW_CUSTOMER','New customer with no repayment history','First-time borrower should receive manual review before large exposure.',15,'medium',true),
('OVERDUE_HISTORY','Customer has overdue or default history','Previous or current overdue loan increases credit risk.',30,'high',true),
('MISSING_KYC','KYC documents or guarantor details incomplete','Incomplete onboarding requires manual review.',25,'high',true),
('BRANCH_DEFAULT_RISK','Branch is inactive or recently suspended due to defaults','Applications from inactive/high-default branches require enhanced review.',25,'high',true),
('STAFF_CONFLICT','Same staff created and approved/recommended transaction','Maker-checker conflict; separate staff approval required.',40,'critical',true)
on conflict(rule_code) do update set title=excluded.title, description=excluded.description, points=excluded.points, severity=excluded.severity, active=excluded.active;

insert into governance_policies(policy_name,policy_value) values
('credit_bureau_live_checks_enabled','false'),
('credit_bureau_default_provider','INTERNAL'),
('credit_bureau_credentials_status','pending CreditRegistry approval'),
('manual_credit_review_required_without_bureau','true'),
('risk_score_manual_review_threshold','40'),
('risk_score_decline_threshold','75')
on conflict(policy_name) do update set policy_value=excluded.policy_value;

create or replace view credit_bureau_readiness_report as
select provider_code, provider_name, environment, enabled, live_checks_allowed,
case when provider_code='INTERNAL' then 'ready'
     when enabled=false then 'waiting_for_credentials'
     when live_checks_allowed=false then 'configured_not_live'
     else 'live' end as readiness_status,
notes, updated_at
from credit_bureau_providers;

create or replace view manual_credit_review_queue as
select mcr.id, c.full_name as customer_name, c.phone, l.id as loan_no, l.principal,
irs.score as internal_score, irs.risk_band, mcr.status, mcr.recommendation,
mcr.created_at, mcr.reviewed_at
from manual_credit_reviews mcr
left join customers c on c.id=mcr.customer_id
left join loans l on l.id=mcr.loan_id
left join internal_risk_scores irs on irs.id=mcr.internal_risk_score_id
order by mcr.created_at desc;

create or replace function calculate_internal_risk_score(p_customer_id uuid, p_loan_id uuid default null)
returns uuid as $$
declare
  v_score int := 0;
  v_factors jsonb := '[]'::jsonb;
  v_band text := 'low';
  v_decision text := 'eligible';
  v_customer customers%rowtype;
  v_loan loans%rowtype;
  v_score_id uuid;
begin
  select * into v_customer from customers where id=p_customer_id;
  if not found then raise exception 'Customer not found'; end if;
  if p_loan_id is not null then select * into v_loan from loans where id=p_loan_id; end if;

  if coalesce(v_customer.bvn,'')='' and coalesce(v_customer.nin,'')='' then
    v_score := v_score + 25; v_factors := v_factors || jsonb_build_object('rule','MISSING_KYC','points',25);
  end if;

  if p_loan_id is not null and coalesce(v_loan.principal,0) >= 400000 then
    v_score := v_score + 20; v_factors := v_factors || jsonb_build_object('rule','HIGH_LOAN_AMOUNT','points',20);
  end if;

  if not exists(select 1 from loans where customer_id=p_customer_id and status in ('closed','approved','disbursed') and (p_loan_id is null or id<>p_loan_id)) then
    v_score := v_score + 15; v_factors := v_factors || jsonb_build_object('rule','NEW_CUSTOMER','points',15);
  end if;

  if exists(select 1 from loans where customer_id=p_customer_id and status in ('defaulted')) then
    v_score := v_score + 30; v_factors := v_factors || jsonb_build_object('rule','OVERDUE_HISTORY','points',30);
  end if;

  if v_score >= 75 then v_band := 'critical'; v_decision := 'decline';
  elsif v_score >= 40 then v_band := 'high'; v_decision := 'manual_review';
  elsif v_score >= 20 then v_band := 'medium'; v_decision := 'manual_review';
  else v_band := 'low'; v_decision := 'eligible'; end if;

  insert into internal_risk_scores(customer_id, loan_id, score, risk_band, decision, factors)
  values(p_customer_id, p_loan_id, least(v_score,100), v_band, v_decision, v_factors)
  returning id into v_score_id;

  if v_decision <> 'eligible' then
    insert into manual_credit_reviews(customer_id, loan_id, internal_risk_score_id, status, notes)
    values(p_customer_id, p_loan_id, v_score_id, 'pending', 'Auto-created by internal risk engine pending manual credit review.');
  end if;

  return v_score_id;
end;
$$ language plpgsql;


-- =========================
-- 13) PHASE 1-4 EXPANSION: CONTRIBUTOR + CREDIT SERVICES + MICROFINANCE SAAS
-- =========================

create table if not exists service_clients (
  id uuid primary key default gen_random_uuid(),
  organization_name text not null,
  client_type text not null default 'microfinance' check(client_type in ('microfinance','cooperative','ngo','vsla','sme_lender','agent_network','other')),
  contact_name text,
  email text unique,
  phone text,
  address text,
  status text default 'lead' check(status in ('lead','onboarding','active','suspended','inactive','rejected')),
  plan_code text default 'starter',
  kyc_status text default 'pending' check(kyc_status in ('pending','verified','rejected')),
  notes text,
  created_at timestamptz default now()
);

create table if not exists customer_consents (
  id uuid primary key default gen_random_uuid(),
  service_client_id uuid references service_clients(id),
  customer_id uuid references customers(id),
  customer_name text not null,
  phone text,
  bvn text,
  nin text,
  consent_type text not null check(consent_type in ('internal_risk_check','credit_bureau_check','bureau_reporting','data_processing','full_credit_services')),
  consent_channel text default 'digital' check(consent_channel in ('digital','paper','sms','whatsapp','agent_captured')),
  consent_text text,
  signed_at timestamptz,
  expires_at timestamptz,
  status text default 'pending' check(status in ('pending','signed','expired','revoked','rejected')),
  evidence_url text,
  created_at timestamptz default now()
);

create table if not exists credit_service_products (
  id uuid primary key default gen_random_uuid(),
  product_code text unique not null,
  product_name text not null,
  description text,
  service_type text not null check(service_type in ('internal_risk_report','credit_bureau_report','bulk_screening','sme_assessment','saas_subscription','implementation')),
  price_amount numeric(14,2) default 0,
  currency text default 'NGN',
  requires_bureau_credentials boolean default false,
  requires_customer_consent boolean default true,
  status text default 'active' check(status in ('active','inactive')),
  created_at timestamptz default now()
);

create table if not exists credit_service_requests (
  id uuid primary key default gen_random_uuid(),
  request_no text unique default concat('CSR-', upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  service_client_id uuid references service_clients(id),
  consent_id uuid references customer_consents(id),
  requested_by uuid references staff_profiles(id),
  request_type text not null default 'internal_risk_report',
  customer_name text,
  customer_phone text,
  bvn text,
  nin text,
  price_amount numeric(14,2) default 0,
  payment_status text default 'unpaid' check(payment_status in ('unpaid','paid','waived','refunded')),
  status text default 'submitted' check(status in ('submitted','awaiting_consent','awaiting_payment','in_review','completed','rejected','cancelled')),
  internal_score int check(internal_score is null or internal_score between 0 and 100),
  risk_band text,
  decision text,
  report_url text,
  created_at timestamptz default now(),
  completed_at timestamptz
);

create table if not exists credit_check_orders (
  id uuid primary key default gen_random_uuid(),
  order_no text unique default concat('CCO-', upper(substr(encode(gen_random_bytes(8),'hex'),1,12))),
  service_request_id uuid references credit_service_requests(id),
  service_client_id uuid references service_clients(id),
  customer_name text,
  service_type text not null,
  amount numeric(14,2) not null default 0,
  currency text default 'NGN',
  status text default 'pending' check(status in ('pending','paid','failed','cancelled','refunded')),
  payment_reference text,
  created_at timestamptz default now()
);

create table if not exists bureau_upload_queue (
  id uuid primary key default gen_random_uuid(),
  provider_code text default 'creditregistry',
  upload_type text not null check(upload_type in ('person','business','account','account_history','default_update','closure','correction')),
  source_table text,
  source_id uuid,
  payload jsonb,
  status text default 'queued' check(status in ('queued','blocked_no_credentials','submitted','accepted','rejected','failed','cancelled')),
  upload_id text,
  transaction_id text,
  error_message text,
  created_at timestamptz default now(),
  processed_at timestamptz
);

create table if not exists saas_subscriptions (
  id uuid primary key default gen_random_uuid(),
  service_client_id uuid references service_clients(id),
  client_name text not null,
  plan_code text not null check(plan_code in ('starter','growth','pro','enterprise')),
  status text default 'trial' check(status in ('trial','active','past_due','suspended','cancelled')),
  monthly_fee numeric(14,2) default 0,
  users_allowed int default 5,
  branches_allowed int default 1,
  started_at timestamptz default now(),
  next_billing_date date,
  created_at timestamptz default now()
);

create table if not exists api_clients (
  id uuid primary key default gen_random_uuid(),
  service_client_id uuid references service_clients(id),
  client_name text not null,
  environment text default 'sandbox' check(environment in ('sandbox','production')),
  status text default 'disabled' check(status in ('disabled','pending_approval','active','suspended','revoked')),
  public_key_ref text,
  secret_key_ref text,
  rate_limit_per_day int default 100,
  last_used_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists revenue_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null check(event_type in ('credit_check','risk_report','bulk_screening','subscription','implementation','training','other')),
  service_client_id uuid references service_clients(id),
  customer_name text,
  amount numeric(14,2) not null default 0,
  currency text default 'NGN',
  status text default 'pending' check(status in ('pending','recognized','paid','failed','refunded')),
  source_reference text,
  created_at timestamptz default now()
);

create or replace view phase_revenue_summary as
select event_type, count(*) as transaction_count, coalesce(sum(amount),0) as total_amount
from revenue_events
group by event_type;

-- Phase 3/4 starter seed data
insert into credit_service_products(product_code,product_name,description,service_type,price_amount,requires_bureau_credentials)
values
 ('RISK-001','AILIFE Internal Risk Report','Internal risk score and manual assessment without live bureau data.','internal_risk_report',500,false),
 ('BULK-001','Bulk Applicant Screening','Bulk screening for small lenders using AILIFE rules and consent workflow.','bulk_screening',10000,false),
 ('BUREAU-001','Credit Bureau Report','CreditRegistry-powered report, activated only after provider approval.','credit_bureau_report',1500,true),
 ('SAAS-STARTER','MFI SaaS Starter','Loan, savings, collections and staff monitoring platform for small lenders.','saas_subscription',25000,false)
on conflict (product_code) do nothing;

insert into service_clients(organization_name,client_type,contact_name,email,phone,status,plan_code,kyc_status,notes)
values ('Demo Cooperative Client','cooperative','Demo Admin','demo-client@ailifeempowerment.com','08000000000','lead','starter','pending','Placeholder client for testing credit services workflow.')
on conflict (email) do nothing;

insert into bureau_upload_queue(upload_type,source_table,status,payload,error_message)
values ('account','loans','blocked_no_credentials','{"provider":"creditregistry","mode":"awaiting_credentials"}'::jsonb,'Awaiting approved CreditRegistry subscriber credentials before live upload.')
on conflict do nothing;

-- =========================
-- V4.2 PRODUCTION CONFIGURATION PATCH
-- =========================
insert into branches(branch_code,name,state,area,status) values
 ('EDE','Ede Branch','Osun','Osun','active'),
 ('OSOGBO','Osogbo Branch','Osun','Osun','active'),
 ('OWODE','Owode Branch','Osun','Osun','active'),
 ('IBADAN1','Ibadan 1','Oyo','Ibadan','active'),
 ('IBADAN2','Ibadan 2','Oyo','Ibadan','active'),
 ('RUMUDARA','Rumudara Branch','Rivers','Port Harcourt','active'),
 ('RUMUKURUSHI','Rumukurushi Branch','Rivers','Port Harcourt','inactive'),
 ('ENEKA','Eneka Branch','Rivers','Port Harcourt','inactive')
on conflict(branch_code) do update set state=excluded.state, area=excluded.area, status=excluded.status;

update staff_profiles set mfa_required=true where email in ('admin@ailifeempowerment.com','finance@ailifeempowerment.com','compliance@ailifeempowerment.com');

insert into staff_profiles(full_name,email,role,branch,mfa_required,status,password_hash) values
('AILIFE Investor Viewer','investor@ailifeempowerment.com','board_viewer','Head Office',true,'active','a55b1fd8d8992ecf3cc32f4d90445d67:8f0625f7e8760a9ec5f20a0b44377d0cce4a04de276b87980bfb061aab25a7f1'),
('AILIFE Credit Officer','credit@ailifeempowerment.com','credit_officer','Head Office',true,'active','a55b1fd8d8992ecf3cc32f4d90445d67:8f0625f7e8760a9ec5f20a0b44377d0cce4a04de276b87980bfb061aab25a7f1'),
('AILIFE Branch Manager','branchmanager@ailifeempowerment.com','branch_manager','Head Office',true,'active','a55b1fd8d8992ecf3cc32f4d90445d67:8f0625f7e8760a9ec5f20a0b44377d0cce4a04de276b87980bfb061aab25a7f1')
on conflict(email) do nothing;

-- v4.4 Financial services expansion: bill payments, airtime credit, POS network, SME cross-border desk
create table if not exists financial_service_requests (
  id bigserial primary key,
  request_no text unique not null,
  service_type text not null,
  requester_name text,
  phone text,
  branch text,
  amount numeric(18,2),
  currency text default 'NGN',
  status text default 'received',
  compliance_status text default 'pending_review',
  payload jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists bill_payment_products (
  id bigserial primary key,
  biller_name text not null,
  category text not null,
  provider_name text,
  settlement_account text,
  commission_rate numeric(8,4) default 0,
  status text default 'configuration'
);

create table if not exists airtime_credit_accounts (
  id bigserial primary key,
  customer_name text not null,
  phone text not null,
  network text,
  credit_limit numeric(18,2) default 0,
  outstanding_balance numeric(18,2) default 0,
  status text default 'active',
  created_at timestamptz default now()
);

create table if not exists pos_terminals (
  id bigserial primary key,
  terminal_serial text unique,
  manufacturer text,
  model text,
  assigned_agent text,
  branch text,
  status text default 'inventory',
  last_seen_at timestamptz,
  risk_flag text
);

create table if not exists sme_cross_border_requests (
  id bigserial primary key,
  request_no text unique not null,
  business_name text not null,
  corridor text not null,
  purpose text,
  amount numeric(18,2),
  currency text,
  beneficiary_details jsonb default '{}'::jsonb,
  kyc_status text default 'pending',
  aml_status text default 'pending',
  partner_route text,
  status text default 'compliance_review',
  created_at timestamptz default now()
);
