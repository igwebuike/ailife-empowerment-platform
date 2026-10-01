BEGIN;

ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS last_login_at timestamptz;

CREATE TABLE IF NOT EXISTS fx_rates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  base_currency text NOT NULL,
  quote_currency text NOT NULL,
  provider_rate numeric(20,8) NOT NULL CHECK(provider_rate > 0),
  customer_rate numeric(20,8) NOT NULL CHECK(customer_rate > 0),
  fixed_fee numeric(14,2) NOT NULL DEFAULT 0,
  percent_fee numeric(8,4) NOT NULL DEFAULT 0,
  source text NOT NULL DEFAULT 'manual',
  effective_at timestamptz NOT NULL DEFAULT now(),
  status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','inactive')),
  created_by uuid REFERENCES staff_profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_fx_rates_pair_effective ON fx_rates(base_currency,quote_currency,effective_at DESC);

ALTER TABLE organizations ADD COLUMN IF NOT EXISTS password_hash text;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS force_password_change boolean NOT NULL DEFAULT false;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS last_login_at timestamptz;

CREATE TABLE IF NOT EXISTS organization_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email text NOT NULL,
  token_hash text NOT NULL,
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  created_by uuid REFERENCES staff_profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO schema_migrations(version,description)
VALUES ('008','Staff workspace, FX rates and Ajo organization portal support')
ON CONFLICT (version) DO NOTHING;
COMMIT;
