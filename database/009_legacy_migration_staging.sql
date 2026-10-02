BEGIN;
CREATE TABLE IF NOT EXISTS legacy_migration_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK(entity_type IN ('customers','staff','loans','transactions','groups','contributions')),
  source_name text,
  file_name text,
  row_count integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'staged' CHECK(status IN ('staged','validated','imported','rejected')),
  validation_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by integer REFERENCES staff_profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  imported_at timestamptz
);
CREATE TABLE IF NOT EXISTS legacy_import_rows (
  id bigserial PRIMARY KEY,
  batch_id uuid NOT NULL REFERENCES legacy_migration_batches(id) ON DELETE CASCADE,
  row_number integer NOT NULL,
  raw_data jsonb NOT NULL,
  validation_status text NOT NULL DEFAULT 'pending' CHECK(validation_status IN ('pending','valid','invalid','imported')),
  validation_errors jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(batch_id,row_number)
);
CREATE INDEX IF NOT EXISTS idx_legacy_import_rows_batch ON legacy_import_rows(batch_id,row_number);
INSERT INTO schema_migrations(version,description) VALUES ('009','Legacy data migration staging and validation') ON CONFLICT (version) DO NOTHING;
COMMIT;
