BEGIN;

-- Support the current application login/staff screens without dropping data
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS branch VARCHAR(150);
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS approval_limit NUMERIC(14,2) DEFAULT 0;
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS can_view_all_branches BOOLEAN DEFAULT FALSE;
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS mfa_required BOOLEAN DEFAULT TRUE;
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS totp_secret TEXT;
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP;

-- Add customer fields needed for onboarding, consent and future bureau integration
ALTER TABLE customers ADD COLUMN IF NOT EXISTS branch_id INTEGER REFERENCES branches(id);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS customer_no VARCHAR(80) UNIQUE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS savings_product VARCHAR(150);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS repayment_method VARCHAR(150);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS consent_credit_check BOOLEAN DEFAULT FALSE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS consent_data_sharing BOOLEAN DEFAULT FALSE;
ALTER TABLE customers ADD COLUMN IF NOT EXISTS risk_score NUMERIC(8,2);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS credit_bureau_status VARCHAR(50) DEFAULT 'not_checked';

-- Keep a branch text value available for legacy pages
UPDATE staff_profiles sp
SET branch = COALESCE(sp.branch, b.name)
FROM branches b
WHERE sp.branch_id = b.id;

-- Seed loan products based on AILIFE operating model
INSERT INTO loan_products
(name, product_type, minimum_amount, maximum_amount, interest_rate, interest_type, tenor_days, repayment_frequency, penalty_rate, status)
VALUES
('Daily Loan', 'micro-loan', 20000, 250000, 20, 'flat', 30, 'daily', 5, 'active'),
('Weekly Loan', 'micro-loan', 50000, 500000, 20, 'flat', 112, 'weekly', 5, 'active'),
('Monthly Loan', 'business-loan', 200000, 5000000, 20, 'flat', 180, 'monthly', 5, 'active'),
('Business Loan', 'business-loan', 100000, 10000000, 20, 'flat', 180, 'monthly', 5, 'active'),
('Emergency Loan', 'short-term', 10000, 100000, 15, 'flat', 30, 'weekly', 5, 'active'),
('Agricultural Loan', 'sector-loan', 50000, 2000000, 18, 'flat', 180, 'monthly', 5, 'active')
ON CONFLICT DO NOTHING;

-- Seed basic chart of accounts
INSERT INTO chart_of_accounts(account_code, account_name, account_type)
VALUES
('1000','Cash on Hand','asset'),
('1010','Bank Account','asset'),
('1100','Loan Portfolio','asset'),
('1110','Interest Receivable','asset'),
('1200','Customer Savings Cash','asset'),
('2000','Customer Savings Liability','liability'),
('2100','Investor Funds','liability'),
('3000','Capital','equity'),
('3100','Retained Earnings','equity'),
('4000','Interest Income','income'),
('4010','Processing Fee Income','income'),
('4020','Penalty Income','income'),
('4030','Credit Check Revenue','income'),
('5000','Salary Expense','expense'),
('5010','Office Expense','expense'),
('5020','Transport Expense','expense'),
('5030','Utilities Expense','expense'),
('5100','Loan Loss Provision','expense')
ON CONFLICT (account_code) DO NOTHING;

-- Seed useful organization settings
INSERT INTO organization_settings(setting_key, setting_value)
VALUES
('organization_name','ASSOCIATION FOR ICON BREEDERS AND LIFE CHANGING EMPOWERMENT'),
('platform_brand','AIBLE Platform'),
('default_currency','NGN'),
('credit_bureau_provider','CreditRegistry'),
('credit_bureau_enabled','pending_credentials'),
('maker_checker_enabled','true'),
('default_penalty_rate','5'),
('approval_limit_area_manager','400000'),
('mfa_required','true')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value;

COMMIT;
