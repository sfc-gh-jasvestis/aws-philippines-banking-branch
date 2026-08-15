-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Branch Network Optimization & Demand Forecasting
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.BSP_BRANCH_SEARCH
  ON REPORT_TEXT
  ATTRIBUTES REGION, METRIC_TYPE, YEAR
  WAREHOUSE = BRANCH_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.BSP_BANKING_DATA
);
