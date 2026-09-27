BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Legacy production compatibility: additive only.
ALTER TABLE kyc_documents ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE kyc_documents ADD COLUMN IF NOT EXISTS file_name text;
ALTER TABLE kyc_documents ADD COLUMN IF NOT EXISTS verification_status varchar(50) DEFAULT 'pending';
ALTER TABLE kyc_documents ADD COLUMN IF NOT EXISTS verified_by integer;

ALTER TABLE transactions ADD COLUMN IF NOT EXISTS type varchar(100);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS status varchar(50) DEFAULT 'approved';
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS channel varchar(50);
ALTER TABLE transactions ADD COLUMN IF NOT EXISTS customer_name varchar(255);
UPDATE transactions SET type=transaction_type WHERE type IS NULL AND transaction_type IS NOT NULL;
UPDATE transactions SET status='approved' WHERE status IS NULL;

CREATE TABLE IF NOT EXISTS document_blobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kyc_document_id integer REFERENCES kyc_documents(id) ON DELETE CASCADE,
  mime_type text NOT NULL,
  size_bytes integer NOT NULL,
  sha256 text NOT NULL,
  content bytea NOT NULL,
  uploaded_by integer REFERENCES staff_profiles(id),
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_document_blobs_kyc ON document_blobs(kyc_document_id);

CREATE TABLE IF NOT EXISTS schema_migrations (
  version text PRIMARY KEY,
  description text NOT NULL,
  applied_by integer REFERENCES staff_profiles(id),
  applied_at timestamptz DEFAULT now()
);
INSERT INTO schema_migrations(version,description) VALUES
('003','AIBLE v5 production table reconciliation'),
('004','Operational GUI and legacy compatibility') ON CONFLICT(version) DO NOTHING;

CREATE TABLE IF NOT EXISTS migration_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation text NOT NULL,
  status text NOT NULL,
  summary jsonb DEFAULT '{}'::jsonb,
  run_by integer REFERENCES staff_profiles(id),
  created_at timestamptz DEFAULT now()
);

COMMIT;
