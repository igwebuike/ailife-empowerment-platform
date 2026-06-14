ALTER TABLE customers ADD COLUMN IF NOT EXISTS savings_product VARCHAR(120);
ALTER TABLE customers ADD COLUMN IF NOT EXISTS repayment_method VARCHAR(80);

CREATE TABLE IF NOT EXISTS savings_products (
  id SERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  minimum_amount NUMERIC(12,2),
  period VARCHAR(120),
  interest_rule TEXT,
  withdrawal_rule TEXT,
  ailife_charge_rule TEXT,
  status VARCHAR(30) DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS repayment_methods (
  id SERIAL PRIMARY KEY,
  name VARCHAR(80) NOT NULL,
  status VARCHAR(30) DEFAULT 'Active',
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organization_settings (
  id SERIAL PRIMARY KEY,
  setting_key VARCHAR(120) UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO savings_products (name, minimum_amount, period, interest_rule, withdrawal_rule, ailife_charge_rule)
VALUES
('Daily Savings', 200, 'Monthly cycle', 'No interest paid', 'Client can withdraw at month end and restart unless on loan or chooses to continue saving', 'AILIFE takes the first savings paid'),
('Weekly Savings', 1000, '4 months, 6 months, or 1 year', '6 months and above attracts 3% per annum; below 6 months attracts charges', 'Withdrawal based on selected product period', 'Below 6 months attracts first installment charge'),
('Monthly Savings', 10000, '12 months and above', '3% per annum', 'Withdrawal after agreed savings period', 'No special charge stated'),
('Target Savings', 0, 'Flexible', 'Interest depends on agreed target terms', 'Client saves toward agreed target amount', 'No fixed charge stated'),
('Fixed Deposit', 200000, '3 months, 6 months, or 1 year', 'Interest depends on amount and tenor', 'Withdrawal at maturity unless otherwise agreed', 'Terms depend on investment agreement')
ON CONFLICT DO NOTHING;

INSERT INTO repayment_methods (name)
VALUES ('Cash'), ('Transfer'), ('POS')
ON CONFLICT DO NOTHING;

INSERT INTO organization_settings (setting_key, setting_value)
VALUES
('customer_care_number', '+2349060085384'),
('support_email', 'ailife018@gmail.com')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value;
