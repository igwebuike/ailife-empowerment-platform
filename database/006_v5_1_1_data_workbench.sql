BEGIN;

CREATE TABLE IF NOT EXISTS workbench_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id integer REFERENCES staff_profiles(id),
  operation text NOT NULL,
  dataset text NOT NULL,
  filters jsonb NOT NULL DEFAULT '{}'::jsonb,
  affected_rows integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'completed',
  result_summary jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_workbench_runs_actor_date ON workbench_runs(actor_id,created_at DESC);

INSERT INTO schema_migrations(version,description) VALUES
('006','AIBLE v5.1.1 staff data and transaction workbench')
ON CONFLICT(version) DO NOTHING;
COMMIT;
