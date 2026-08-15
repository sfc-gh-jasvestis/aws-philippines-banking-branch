-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Branch Network Optimization & Demand Forecasting
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_INGEST_TRAFFIC
  WAREHOUSE = BRANCH_WH
  SCHEDULE = 'USING CRON 0 6 * * * UTC'
  COMMENT = 'Ingest daily foot traffic data from Location Service'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_REFRESH_CATCHMENTS
  WAREHOUSE = BRANCH_WH
  AFTER APP.TASK_INGEST_TRAFFIC
  COMMENT = 'Refresh catchment area analysis with H3 aggregation'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_FORECAST_DEMAND
  WAREHOUSE = BRANCH_WH
  AFTER APP.TASK_REFRESH_CATCHMENTS
  COMMENT = 'Generate 90-day demand forecasts per branch'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_FORECAST_DEMAND RESUME;
ALTER TASK APP.TASK_REFRESH_CATCHMENTS RESUME;
ALTER TASK APP.TASK_INGEST_TRAFFIC RESUME;
