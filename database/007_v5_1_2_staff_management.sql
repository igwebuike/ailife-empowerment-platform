BEGIN;
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS force_password_change boolean NOT NULL DEFAULT false;
-- Promote only the platform owner account to the distinct super-admin role.
UPDATE staff_profiles SET role='super_admin' WHERE lower(email)=lower('eugene.ebem@aibleplatform.com');
INSERT INTO schema_migrations(version,description) VALUES ('007','Staff management and super-admin separation') ON CONFLICT (version) DO NOTHING;
COMMIT;
