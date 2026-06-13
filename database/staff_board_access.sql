-- AILIFE Staff, Branch, Board/Investor Access Upgrade
-- Run this in Render PostgreSQL psql.
create extension if not exists pgcrypto;

create table if not exists branches (
  id uuid primary key default gen_random_uuid(),
  branch_code text unique,
  name text not null unique,
  state text,
  area text,
  status text default 'active',
  created_at timestamptz default now()
);

alter table branches add column if not exists branch_code text;
alter table branches add column if not exists state text;
alter table branches add column if not exists area text;
alter table branches add column if not exists status text default 'active';

create table if not exists staff_profiles (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text unique not null,
  phone text,
  department text,
  role text not null,
  branch_id uuid references branches(id),
  branch text,
  area text,
  approval_limit numeric(14,2) default 0,
  can_view_all_branches boolean default false,
  mfa_required boolean default true,
  password_hash text,
  totp_secret text,
  status text default 'active',
  created_at timestamptz default now()
);

alter table staff_profiles drop constraint if exists staff_profiles_role_check;
alter table staff_profiles drop constraint if exists staff_profiles_status_check;
alter table staff_profiles add column if not exists department text;
alter table staff_profiles add column if not exists branch text;
alter table staff_profiles add column if not exists area text;
alter table staff_profiles add column if not exists approval_limit numeric(14,2) default 0;
alter table staff_profiles add column if not exists can_view_all_branches boolean default false;
alter table staff_profiles add column if not exists mfa_required boolean default true;
alter table staff_profiles add column if not exists password_hash text;
alter table staff_profiles add column if not exists totp_secret text;
alter table staff_profiles add column if not exists status text default 'active';

create table if not exists role_permissions (
  id uuid primary key default gen_random_uuid(),
  role text not null,
  permission text not null,
  created_at timestamptz default now(),
  unique(role, permission)
);

create table if not exists staff_branch_access (
  id uuid primary key default gen_random_uuid(),
  staff_id uuid references staff_profiles(id) on delete cascade,
  branch_id uuid references branches(id) on delete cascade,
  created_at timestamptz default now(),
  unique(staff_id, branch_id)
);

insert into branches(branch_code, name, state, area, status) values
('HQ','Head Office Branch','Osun State','Osun State','active'),
('EDE','Ede Branch','Osun State','Osun State','active'),
('OSG','Osogbo Branch','Osun State','Osun State','active'),
('OWD','Owode Branch','Osun State','Osun State','active'),
('IB1','Ibadan 1','Oyo State','Ibadan','active'),
('IB2','Ibadan 2','Oyo State','Ibadan','active'),
('RMD','Rumudara Branch','Rivers State','Port Harcourt','active'),
('RMK','Rumukurushi Branch','Rivers State','Port Harcourt','inactive'),
('ENK','Eneka Branch','Rivers State','Port Harcourt','inactive')
on conflict(name) do update set state=excluded.state, area=excluded.area, status=excluded.status;

insert into role_permissions(role, permission) values
('board_of_trustees','view_all_reports'),('board_of_trustees','view_audit_logs'),('board_of_trustees','view_all_branches'),
('governing_council','view_all_reports'),('governing_council','view_governance'),('governing_council','view_all_branches'),
('investor','view_investor_dashboard'),('investor','view_portfolio_summary'),('investor','view_board_reports'),
('executive_director','all_access'),
('program_director','approve_large_loans'),('program_director','view_all_branches'),('program_director','view_staff_performance'),
('program_manager','view_program_reports'),('program_manager','view_branch_reports'),
('area_manager','approve_loans_up_to_400k'),('area_manager','view_assigned_area'),
('branch_manager','recommend_loans'),('branch_manager','disburse_approved_loans'),('branch_manager','view_own_branch'),
('credit_officer','onboard_clients'),('credit_officer','process_loan_applications'),('credit_officer','view_assigned_clients'),
('accountant','view_financial_reports'),('accountant','record_reconciliations'),('accountant','view_transactions'),
('program_officer','view_program_data'),('program_officer','record_field_reports'),
('secretary','basic_client_intake'),('receptionist','basic_client_intake')
on conflict(role, permission) do nothing;
