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
select date(created_at) report_date, branch, type, status, count(*) transaction_count, sum(amount) total_amount
from transactions
group by date(created_at), branch, type, status;

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

-- Render PostgreSQL RLS starter policies. For Render Postgres these auth.* calls are ignored only if not executed there.
do $$ begin
  alter table staff_profiles enable row level security; alter table customers enable row level security; alter table savings_accounts enable row level security; alter table loans enable row level security; alter table transactions enable row level security; alter table risk_alerts enable row level security; alter table audit_logs enable row level security; alter table governance_policies enable row level security; alter table kyc_documents enable row level security; alter table agents enable row level security; alter table branch_cash_accounts enable row level security; alter table notification_outbox enable row level security;
exception when undefined_function then null; end $$;

do $$ begin create policy "customers insert public onboarding" on customers for insert with check (true); exception when duplicate_object then null; end $$;
do $$ begin create policy "staff read write authenticated" on staff_profiles for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "customers staff all" on customers for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "all operational tables staff" on savings_accounts for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "loans staff all" on loans for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "transactions staff all" on transactions for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "alerts staff all" on risk_alerts for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "audit staff read" on audit_logs for select using (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "policies staff all" on governance_policies for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "documents staff all" on kyc_documents for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "agents staff all" on agents for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "cash staff all" on branch_cash_accounts for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;
do $$ begin create policy "outbox staff all" on notification_outbox for all using (auth.role()='authenticated') with check (auth.role()='authenticated'); exception when duplicate_object then null; end $$;


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
