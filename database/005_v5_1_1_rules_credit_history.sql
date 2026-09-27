BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS decision_rule_sets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL,
  name text NOT NULL,
  description text,
  version integer NOT NULL DEFAULT 1,
  status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published','retired')),
  created_by integer REFERENCES staff_profiles(id),
  published_by integer REFERENCES staff_profiles(id),
  published_at timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(code,version)
);

CREATE TABLE IF NOT EXISTS decision_rules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_set_id uuid NOT NULL REFERENCES decision_rule_sets(id) ON DELETE CASCADE,
  rule_code text NOT NULL,
  name text NOT NULL,
  metric_key text NOT NULL,
  operator text NOT NULL CHECK(operator IN ('eq','neq','gt','gte','lt','lte')),
  compare_value numeric NOT NULL,
  action_type text NOT NULL CHECK(action_type IN ('add_points','subtract_points','set_decision','manual_review','route_role')),
  action_value text NOT NULL,
  priority integer NOT NULL DEFAULT 100,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  UNIQUE(rule_set_id,rule_code)
);

CREATE TABLE IF NOT EXISTS decision_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id integer NOT NULL REFERENCES customers(id),
  loan_id integer REFERENCES loans(id),
  rule_set_id uuid REFERENCES decision_rule_sets(id),
  rule_set_version integer,
  input_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  matched_rules jsonb NOT NULL DEFAULT '[]'::jsonb,
  score integer NOT NULL DEFAULT 0,
  risk_band text NOT NULL DEFAULT 'unrated',
  decision text NOT NULL DEFAULT 'manual_review',
  route_role text,
  evaluated_by integer REFERENCES staff_profiles(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS credit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id integer NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  source_type text NOT NULL,
  source_id text,
  amount numeric(14,2),
  status text,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  data jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE(source_type,source_id,event_type)
);
CREATE INDEX IF NOT EXISTS idx_credit_events_customer_date ON credit_events(customer_id,occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_decision_runs_customer_date ON decision_runs(customer_id,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_decision_rules_set_priority ON decision_rules(rule_set_id,priority);

-- Existing Ajo/Esusu history becomes part of the linked customer credit timeline.
INSERT INTO credit_events(customer_id,event_type,source_type,source_id,amount,status,occurred_at,data)
SELECT m.customer_id,
       CASE WHEN lower(c.status)='paid' THEN 'CONTRIBUTION_PAID' WHEN lower(c.status) IN ('overdue','missed') THEN 'CONTRIBUTION_MISSED' ELSE 'CONTRIBUTION_RECORDED' END,
       'contribution',c.id::text,c.amount,c.status,coalesce(c.paid_at,c.created_at),
       jsonb_build_object('organization_id',c.organization_id,'member_id',c.member_id,'plan_id',c.plan_id,'channel',c.channel,'reference',c.provider_reference)
FROM contributions c JOIN organization_members m ON m.id=c.member_id
WHERE m.customer_id IS NOT NULL
ON CONFLICT(source_type,source_id,event_type) DO NOTHING;

-- Existing internal scores and bureau checks also become credit events.
INSERT INTO credit_events(customer_id,event_type,source_type,source_id,status,occurred_at,data)
SELECT customer_id,'INTERNAL_RISK_SCORE','internal_risk_score',id::text,decision,coalesce(calculated_at,created_at),jsonb_build_object('score',score,'risk_band',risk_band,'decision',decision,'factors',factors)
FROM internal_risk_scores WHERE customer_id IS NOT NULL
ON CONFLICT(source_type,source_id,event_type) DO NOTHING;

INSERT INTO credit_events(customer_id,event_type,source_type,source_id,status,occurred_at,data)
SELECT customer_id,'CREDIT_BUREAU_CHECK','credit_bureau_check',id::text,status,coalesce(completed_at,created_at),jsonb_build_object('bureau_score',bureau_score,'bureau_decision',bureau_decision,'provider_id',provider_id)
FROM credit_bureau_checks WHERE customer_id IS NOT NULL
ON CONFLICT(source_type,source_id,event_type) DO NOTHING;

-- Keep future contribution activity linked automatically when a group member is linked to a customer.
CREATE OR REPLACE FUNCTION aible_credit_event_from_contribution() RETURNS trigger AS $$
DECLARE cid integer; et text;
BEGIN
  SELECT customer_id INTO cid FROM organization_members WHERE id=NEW.member_id;
  IF cid IS NULL THEN RETURN NEW; END IF;
  et := CASE WHEN lower(NEW.status)='paid' THEN 'CONTRIBUTION_PAID' WHEN lower(NEW.status) IN ('overdue','missed') THEN 'CONTRIBUTION_MISSED' ELSE 'CONTRIBUTION_RECORDED' END;
  INSERT INTO credit_events(customer_id,event_type,source_type,source_id,amount,status,occurred_at,data)
  VALUES(cid,et,'contribution',NEW.id::text,NEW.amount,NEW.status,coalesce(NEW.paid_at,NEW.created_at),jsonb_build_object('organization_id',NEW.organization_id,'member_id',NEW.member_id,'plan_id',NEW.plan_id,'channel',NEW.channel,'reference',NEW.provider_reference))
  ON CONFLICT(source_type,source_id,event_type) DO UPDATE SET amount=EXCLUDED.amount,status=EXCLUDED.status,occurred_at=EXCLUDED.occurred_at,data=EXCLUDED.data;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_credit_event_contribution ON contributions;
CREATE TRIGGER trg_credit_event_contribution AFTER INSERT OR UPDATE ON contributions FOR EACH ROW EXECUTE FUNCTION aible_credit_event_from_contribution();

CREATE OR REPLACE FUNCTION aible_credit_event_from_risk_score() RETURNS trigger AS $$
BEGIN
  IF NEW.customer_id IS NULL THEN RETURN NEW; END IF;
  INSERT INTO credit_events(customer_id,event_type,source_type,source_id,status,occurred_at,data)
  VALUES(NEW.customer_id,'INTERNAL_RISK_SCORE','internal_risk_score',NEW.id::text,NEW.decision,coalesce(NEW.calculated_at,NEW.created_at),jsonb_build_object('score',NEW.score,'risk_band',NEW.risk_band,'decision',NEW.decision,'factors',NEW.factors))
  ON CONFLICT(source_type,source_id,event_type) DO UPDATE SET status=EXCLUDED.status,occurred_at=EXCLUDED.occurred_at,data=EXCLUDED.data;
  RETURN NEW;
END; $$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_credit_event_risk_score ON internal_risk_scores;
CREATE TRIGGER trg_credit_event_risk_score AFTER INSERT OR UPDATE ON internal_risk_scores FOR EACH ROW EXECUTE FUNCTION aible_credit_event_from_risk_score();

INSERT INTO decision_rule_sets(code,name,description,version,status)
VALUES('AIBLE-CREDIT','AIBLE Credit Decision Rules','Explainable internal decision rules. This is not a FICO score.',1,'draft')
ON CONFLICT(code,version) DO NOTHING;

INSERT INTO decision_rules(rule_set_id,rule_code,name,metric_key,operator,compare_value,action_type,action_value,priority)
SELECT s.id,v.rule_code,v.name,v.metric_key,v.operator,v.compare_value,v.action_type,v.action_value,v.priority
FROM decision_rule_sets s
CROSS JOIN (VALUES
 ('AJO-ON-TIME-95','Strong contribution consistency','contribution_on_time_rate','gte',95,'add_points','80',10),
 ('AJO-MISSED-2','Repeated missed contributions','contribution_missed_count','gte',2,'subtract_points','120',20),
 ('BUREAU-700','Strong bureau score','bureau_score','gte',700,'add_points','100',30),
 ('BUREAU-LOW','Low bureau score requires review','bureau_score','lt',550,'manual_review','bureau_score_below_threshold',40)
) AS v(rule_code,name,metric_key,operator,compare_value,action_type,action_value,priority)
WHERE s.code='AIBLE-CREDIT' AND s.version=1
ON CONFLICT(rule_set_id,rule_code) DO NOTHING;

INSERT INTO schema_migrations(version,description) VALUES
('005','AIBLE v5.1.1 decision rules and unified customer credit history')
ON CONFLICT(version) DO NOTHING;
COMMIT;
