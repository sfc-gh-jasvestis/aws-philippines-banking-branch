-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-incident alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TRANSACTIONS.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic incident-handling knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.INCIDENT_DOCS AS
WITH types AS (
  SELECT DISTINCT r.INCIDENT_TYPE, a.CATEGORY
  FROM RAW.BRANCH_DAILY r JOIN RAW.BRANCHES a ON a.ID = r.ENTITY_ID
  WHERE r.FAILED_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, INCIDENT_TYPE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  INCIDENT_TYPE,
  CATEGORY || ' - ' || INCIDENT_TYPE || ' incident handling' AS TITLE,
  'Synthetic demo SOP. Branch format: ' || CATEGORY || '. Incident type: ' || INCIDENT_TYPE || '. '
  || 'Step 1: open an incident ticket, note the affected counters or machines and post a customer notice at the branch entrance. '
  || 'Step 2: ' || CASE
       WHEN INCIDENT_TYPE = 'Queue overflow' THEN 'open every staffed counter, move simple deposits and withdrawals to the ATM and deposit machines, and ask the area manager for a floating teller if the wait stays above 30 minutes.'
       WHEN INCIDENT_TYPE = 'Teller system downtime' THEN 'switch the affected counters to the offline transaction log, call the IT service desk with the terminal IDs, and post-key logged transactions once the system is restored.'
       WHEN INCIDENT_TYPE = 'Cash vault variance' THEN 'stop vault movements, run a dual-control recount with the branch head and cash custodian, and report any unresolved variance to branch audit the same day.'
       WHEN INCIDENT_TYPE = 'ATM cash-out' THEN 'request an emergency replenishment from the cash-in-transit provider, set the ATM out-of-service message, and review the replenishment forecast for the site.'
       WHEN INCIDENT_TYPE = 'Card reader fault' THEN 'take the machine out of service, retain any captured cards under dual control, and log a field-service call with the ATM vendor.'
       WHEN INCIDENT_TYPE = 'Network link down' THEN 'fail over to the backup link, confirm that ATMs and counters reconnect, and escalate to the network operations centre if the backup link is also down.'
       WHEN INCIDENT_TYPE = 'Cheque clearing delay' THEN 'check the cheque batch cut-off, rescan rejected items, and inform business clients of the new expected credit date.'
       ELSE 'review the incident against the branch profile and escalate if unexplained.'
     END
  || ' Step 3: if ATM downtime at the branch exceeds 5% or the average queue wait exceeds 25 minutes after the fix, keep the ticket open and request a branch review. '
  || 'Step 4: record the resolution; if transactions failed or the queue wait SLA was breached, log the breach for the weekly branch operations report.' AS CONTENT
FROM types;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.INCIDENT_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, INCIDENT_TYPE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, INCIDENT_TYPE, CONTENT FROM SEARCH.INCIDENT_DOCS);

-- ---------- ATM downtime anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.ATM_DOWNTIME_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, ATM_DOWNTIME_PCT::FLOAT AS ATM_DOWNTIME
FROM RAW.BRANCH_DAILY;
CREATE OR REPLACE VIEW ML.ATM_DOWNTIME_TRAIN AS
SELECT * FROM ML.ATM_DOWNTIME_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ATM_DOWNTIME_SERIES);
CREATE OR REPLACE VIEW ML.ATM_DOWNTIME_DETECT AS
SELECT * FROM ML.ATM_DOWNTIME_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.ATM_DOWNTIME_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.ATM_DOWNTIME_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ATM_DOWNTIME_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ATM_DOWNTIME',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.ATM_DOWNTIME_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS ATM_DOWNTIME, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.ATM_DOWNTIME_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.ATM_DOWNTIME_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'ATM_DOWNTIME'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.BRANCH_ANALYTICS
  TABLES (
    branches AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'branches', 'sites')
      COMMENT = 'One row per fictional bank branch in a Philippine city, 90-day totals',
    risk AS ML.FAILURE_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day failed-transaction probability per branch',
    incidents AS CURATED.INCIDENT_SUMMARY PRIMARY KEY (INCIDENT_TYPE)
      COMMENT = 'Incidents, failed transactions and queue SLA breaches by incident type, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Network-wide totals per day'
  )
  RELATIONSHIPS (risk_branch AS risk (ENTITY_ID) REFERENCES branches)
  FACTS (
    branches.incidents_f AS INCIDENT_COUNT,
    branches.failed_f AS FAILED_COUNT,
    branches.breaches_f AS SLA_BREACH_COUNT,
    branches.txns_f AS TXN_COUNT,
    branches.value_f AS VALUE_PHP,
    branches.audit_due_f AS AUDIT_DUE,
    branches.audit_done_f AS AUDIT_COMPLETED,
    risk.failure_prob_f AS FAILURE_PROB_7D,
    incidents.type_incidents_f AS INCIDENT_COUNT,
    incidents.type_failed_f AS FAILED_COUNT,
    incidents.type_breaches_f AS SLA_BREACH_COUNT,
    incidents.type_value_f AS EXPOSED_VALUE_PHP,
    daily.day_incidents_f AS INCIDENT_COUNT,
    daily.day_failed_f AS FAILED_COUNT,
    daily.day_value_f AS VALUE_PHP
  )
  DIMENSIONS (
    branches.branch_id AS ENTITY_ID WITH SYNONYMS = ('branch', 'branch code', 'entity'),
    branches.branch_name AS ENTITY_NAME,
    branches.city AS REGION WITH SYNONYMS = ('city', 'region', 'location')
      COMMENT = 'Philippine city of the branch',
    branches.branch_format AS CATEGORY WITH SYNONYMS = ('format', 'branch type', 'site type'),
    branches.risk_tier AS RISK_TIER COMMENT = 'Branch operational risk tier 1 (low) to 3 (high)',
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    incidents.incident_type AS INCIDENT_TYPE WITH SYNONYMS = ('incident', 'incident reason', 'outage type'),
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    branches.branch_total AS COUNT(branches.branch_id)
      WITH SYNONYMS = ('number of branches', 'number of entities', 'how many branches'),
    branches.incident_free_pct AS 100 * (SUM(branches.txns_f) - SUM(branches.incidents_f)) / NULLIF(SUM(branches.txns_f), 0)
      WITH SYNONYMS = ('incident-free transaction rate', 'incident-free rate')
      COMMENT = 'Transactions not touched by an incident / transactions processed',
    branches.failure_share_pct AS 100 * SUM(branches.failed_f) / NULLIF(SUM(branches.incidents_f), 0)
      COMMENT = 'Failed transactions / incidents raised',
    branches.incidents_raised AS SUM(branches.incidents_f) WITH SYNONYMS = ('incidents', 'incident volume'),
    branches.failed_transactions AS SUM(branches.failed_f) WITH SYNONYMS = ('failures', 'failed transactions'),
    branches.sla_breaches AS SUM(branches.breaches_f) WITH SYNONYMS = ('queue SLA breaches', 'SLA misses'),
    branches.transactions_processed AS SUM(branches.txns_f),
    branches.total_value_php AS SUM(branches.value_f) WITH SYNONYMS = ('value', 'value in PHP'),
    branches.audit_compliance_pct AS 100 * SUM(branches.audit_done_f) / NULLIF(SUM(branches.audit_due_f), 0)
      COMMENT = 'Cash and ATM audits completed / audits due',
    risk.avg_failure_prob AS AVG(risk.failure_prob_f),
    incidents.type_incidents AS SUM(incidents.type_incidents_f),
    incidents.type_failed AS SUM(incidents.type_failed_f),
    incidents.type_breaches AS SUM(incidents.type_breaches_f),
    incidents.type_failed_share_pct AS 100 * SUM(incidents.type_failed_f) / NULLIF(SUM(incidents.type_incidents_f), 0),
    daily.daily_incidents AS SUM(daily.day_incidents_f),
    daily.daily_failed AS SUM(daily.day_failed_f),
    daily.daily_value_php AS SUM(daily.day_value_f)
  )
  COMMENT = 'Synthetic Philippine bank branch operations analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.BRANCH_AGENT
  COMMENT = 'Branch operations assistant over a synthetic Philippine bank branch network'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give branch IDs and numbers with units (PHP, %)."
  orchestration: "Use branch_analyst for branches, cities, branch formats, transactions, incidents, failed transactions, queue SLA breaches, cash audit compliance, incident types and failed-transaction risk. Use sop_search for incident-handling procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: branch_analyst
      description: "Branch count, transactions processed, value in PHP, incidents, failed transactions, queue SLA breaches, incident-free transaction rate, cash audit compliance, incident types and failed-transaction risk scores by branch, city and format"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic branch incident-handling SOPs by branch format and incident type"
tool_resources:
  branch_analyst:
    semantic_view: __DEMO_DB__.APP.BRANCH_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.INCIDENT_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;
-- ---------- Live-incident alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), BRANCH_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, AMOUNT_PHP FLOAT, WAIT_SECONDS FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION PH_BANKING_BRANCH_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALERTS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (BRANCH_ID, EVENT_TS, AMOUNT_PHP, WAIT_SECONDS, SOP_HINT)
    SELECT p.BRANCH_ID, p.EVENT_TS, p.AMOUNT_PHP, p.WAIT_SECONDS,
           'Check ' || r.CATEGORY || ' incident SOPs; current risk band ' || COALESCE(s.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TRANSACTIONS p
    JOIN RAW.BRANCHES r ON r.ID = p.BRANCH_ID
    LEFT JOIN ML.FAILURE_RISK_SCORES s ON s.ENTITY_ID = p.BRANCH_ID
    WHERE p.STATUS = 'INCIDENT'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BRANCH_ID = p.BRANCH_ID AND l.EVENT_TS = p.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('PH_BANKING_BRANCH_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Branch incident alert',
      'New live branch incidents logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_INCIDENT_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TRANSACTIONS p
    WHERE p.STATUS = 'INCIDENT'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.BRANCH_ID = p.BRANCH_ID AND l.EVENT_TS = p.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALERTS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.INCIDENT_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.FAILURE_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.FAILURE_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.FAILURE_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'RISK_TIER', RISK_TIER, 'BRANCH_AGE_YEARS', BRANCH_AGE_YEARS,
             'ATM_DOWNTIME_PCT', ATM_DOWNTIME_PCT, 'AVG_WAIT_MIN', AVG_WAIT_MIN,
             'ATM_DOWNTIME_7D', ATM_DOWNTIME_7D, 'FAILED_30D', FAILED_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:FAILURE::FLOAT, 4) AS FAILURE_PROB_7D,
         CASE WHEN PRED:probability:FAILURE::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:FAILURE::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
