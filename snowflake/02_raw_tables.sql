-- Synthetic branch-day observations for a fictional Philippine retail bank's branch network.
-- A branch is one fictional site in one of five Philippine cities.
-- Nothing is seeded as a prediction. Randomness is HASH-seeded, so every rebuild
-- is reproducible: per-branch failure propensity, drift between cash and ATM
-- audits, missed audits, format-weighted incident types, incidents resolved
-- without a failed transaction, and two city-wide power interruptions.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.BRANCHES AS
WITH branches AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS BRANCH_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 40))
), draws AS (
  SELECT BRANCH_INDEX,
         MOD(ABS(HASH(BRANCH_INDEX, 'phbb-age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(BRANCH_INDEX, 'phbb-rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(BRANCH_INDEX, 'phbb-audit')), 1000000) / 1e6 AS U_AUDIT,
         MOD(ABS(HASH(BRANCH_INDEX, 'phbb-discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(BRANCH_INDEX, 'phbb-tier')), 1000000) / 1e6 AS U_TIER
  FROM branches
)
SELECT 'BR-' || LPAD(BRANCH_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic branch ' || LPAD(BRANCH_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (5 and 8 are coprime): every city and format is present.
       CASE MOD(BRANCH_INDEX, 5) WHEN 0 THEN 'Quezon City' WHEN 1 THEN 'Cebu City'
            WHEN 2 THEN 'Davao City' WHEN 3 THEN 'Iloilo City' ELSE 'Cagayan de Oro' END AS REGION,
       CASE MOD(BRANCH_INDEX, 8) WHEN 0 THEN 'Full-service branch' WHEN 1 THEN 'Full-service branch'
            WHEN 2 THEN 'Full-service branch' WHEN 3 THEN 'Mall branch' WHEN 4 THEN 'Mall branch'
            WHEN 5 THEN 'Business centre' WHEN 6 THEN 'Micro branch' ELSE 'Off-site ATM hub' END AS CATEGORY,
       BRANCH_INDEX,
       1 + FLOOR(U_TIER * 3) AS RISK_TIER,
       ROUND(0.5 + U_AGE * 24.5, 1) AS BRANCH_AGE_YEARS,
       -- Base daily probability of a failed-transaction incident 0.5%-3.2%;
       -- ~15% of branches are chronically weak (x3).
       (0.005 + U_RATE * 0.027) * IFF(U_RATE > 0.85, 3, 1) AS BASE_FAILURE_RATE,
       7 * (1 + FLOOR(U_AUDIT * 3)) AS AUDIT_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS AUDIT_COMPLETION_PROB,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.BRANCH_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), city_events AS (
  -- Two city-wide power interruptions; every branch in the city raises an
  -- incident that is resolved once power is restored.
  SELECT * FROM VALUES (31, 'Cebu City'), (58, 'Davao City') AS o(DAY_INDEX, REGION)
), base AS (
  SELECT r.ID AS ENTITY_ID, r.BRANCH_INDEX, r.CATEGORY, r.REGION, r.BRANCH_AGE_YEARS,
         r.BASE_FAILURE_RATE, r.AUDIT_INTERVAL_DAYS, r.AUDIT_COMPLETION_PROB,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         MOD(d.DAY_INDEX + r.BRANCH_INDEX * 5, r.AUDIT_INTERVAL_DAYS) AS DAYS_SINCE_AUDIT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-fail')), 1000000) / 1e6 AS U_FAIL,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-detect')), 1000000) / 1e6 AS U_DETECT,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-clear')), 1000000) / 1e6 AS U_CLEAR,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-type')), 1000000) / 1e6 AS U_TYPE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-done')), 1000000) / 1e6 AS U_DONE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(r.ID, d.DAY_INDEX, 'phbb-sla')), 1000000) / 1e6 AS U_SLA,
         e.REGION IS NOT NULL AS CITY_EVENT
  FROM RAW.BRANCHES r CROSS JOIN days d
  LEFT JOIN city_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = r.REGION
), audit AS (
  SELECT *,
         IFF(DAYS_SINCE_AUDIT = 0, 1, 0) AS AUDIT_DUE,
         IFF(DAYS_SINCE_AUDIT = 0 AND U_DONE < AUDIT_COMPLETION_PROB, 1, 0) AS AUDIT_COMPLETED,
         -- Cash and ATM drift rises between audits; weak audit discipline carries it over.
         DAYS_SINCE_AUDIT / AUDIT_INTERVAL_DAYS + (1 - AUDIT_COMPLETION_PROB) AS DRIFT
  FROM base
), failures AS (
  SELECT *,
         CASE WHEN U_FAIL < LEAST(0.5, BASE_FAILURE_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + BRANCH_AGE_YEARS / 4))) / 4 THEN 2
              WHEN U_FAIL < LEAST(0.5, BASE_FAILURE_RATE * (0.4 + 1.6 * DRIFT) * (1 + 1 / (1 + BRANCH_AGE_YEARS / 4))) THEN 1
              ELSE 0 END AS FAILURE_RISK_COUNT
  FROM audit
), incidents AS (
  SELECT *,
         -- About 85% of at-risk days raise an incident that ends in failed
         -- transactions; the rest recover without one being logged.
         IFF(CITY_EVENT, 0, IFF(U_DETECT < 0.85, FAILURE_RISK_COUNT, 0)) AS FAILED_COUNT,
         -- Incidents resolved without a failed transaction: higher for busy formats.
         IFF(CITY_EVENT, 1, IFF(U_CLEAR < CASE CATEGORY WHEN 'Off-site ATM hub' THEN 0.21
                                                         WHEN 'Mall branch' THEN 0.13
                                                         WHEN 'Business centre' THEN 0.11 ELSE 0.07 END, 1, 0)) AS CLEARED_COUNT
  FROM failures
), measured AS (
  SELECT *,
         FAILED_COUNT + CLEARED_COUNT AS INCIDENT_COUNT,
         ROUND(CASE CATEGORY WHEN 'Off-site ATM hub' THEN 1450 WHEN 'Mall branch' THEN 1150
                             WHEN 'Business centre' THEN 520 WHEN 'Micro branch' THEN 230 ELSE 860 END
               * (0.7 + 0.6 * U_VOLUME) * (1 + 0.8 * FAILURE_RISK_COUNT)) AS TXN_COUNT,
         CASE CATEGORY WHEN 'Off-site ATM hub' THEN 4800 WHEN 'Mall branch' THEN 4100
                       WHEN 'Business centre' THEN 36500 WHEN 'Micro branch' THEN 3300 ELSE 6700 END
           * (0.8 + 0.4 * U_NOISE) AS AVG_TXN_PHP
  FROM incidents
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE,
       TXN_COUNT,
       ROUND(TXN_COUNT * AVG_TXN_PHP, 2) AS VALUE_PHP,
       INCIDENT_COUNT, FAILED_COUNT,
       IFF(FAILED_COUNT > 0 AND U_SLA < 0.6, 1, 0) AS SLA_BREACHED,
       CASE WHEN INCIDENT_COUNT = 0 THEN 'None'
            WHEN CITY_EVENT THEN 'Area power interruption'
            WHEN CATEGORY = 'Full-service branch' THEN IFF(U_TYPE < 0.5, 'Queue overflow', IFF(U_TYPE < 0.8, 'Teller system downtime', 'Cash vault variance'))
            WHEN CATEGORY = 'Mall branch' THEN IFF(U_TYPE < 0.45, 'ATM cash-out', IFF(U_TYPE < 0.8, 'Queue overflow', 'Card reader fault'))
            WHEN CATEGORY = 'Business centre' THEN IFF(U_TYPE < 0.55, 'Teller system downtime', 'Cheque clearing delay')
            WHEN CATEGORY = 'Micro branch' THEN IFF(U_TYPE < 0.45, 'Network link down', IFF(U_TYPE < 0.8, 'ATM cash-out', 'Cash vault variance'))
            ELSE IFF(U_TYPE < 0.5, 'ATM cash-out', IFF(U_TYPE < 0.75, 'Card reader fault', 'Network link down')) END AS INCIDENT_TYPE,
       AUDIT_DUE, AUDIT_COMPLETED,
       ROUND(0.6 + 2.2 * DRIFT + 3.1 * FAILURE_RISK_COUNT + U_NOISE * 0.9, 2) AS ATM_DOWNTIME_PCT,
       ROUND(9 + 7 * DRIFT + 11 * FAILURE_RISK_COUNT + U_NOISE * 5, 1) AS AVG_WAIT_MIN,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM measured;

-- Branch control document coverage per branch (snapshot).
CREATE TABLE RAW.CONTROL_DOCUMENTS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Full-service branch' THEN 'Cash-handling procedure attestation'
                     WHEN 'Mall branch' THEN 'ATM replenishment log'
                     WHEN 'Business centre' THEN 'Cheque processing checklist'
                     WHEN 'Micro branch' THEN 'Dual-control key register'
                     ELSE 'ATM site security inspection' END AS DOC_TYPE,
       1 + MOD(ABS(HASH(ID, 'phbb-req')), 4) AS REQUIRED_QTY,
       MOD(ABS(HASH(ID, 'phbb-file')), 5) AS ON_FILE_QTY,
       IFF(MOD(ABS(HASH(ID, 'phbb-file')), 5) < 1 + MOD(ABS(HASH(ID, 'phbb-req')), 4),
           MOD(ABS(HASH(ID, 'phbb-pending')), 3), 0) AS PENDING_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.BRANCHES;
