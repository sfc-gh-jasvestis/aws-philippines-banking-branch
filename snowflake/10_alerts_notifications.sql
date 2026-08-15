-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Branch Network Optimization & Demand Forecasting
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_philippines_banking_branch_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('jonathan.asvestis@snowflake.com');

-- Alert: UNDERPERFORM_ALERT
CREATE OR REPLACE ALERT APP.UNDERPERFORM_ALERT
  WAREHOUSE = BRANCH_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Branch underperforming — consolidation candidate'
IF (EXISTS (
  SELECT 1 FROM CURATED.BRANCH_PERFORMANCE
  WHERE 1=1 -- Condition: BRANCH_ROI < -5% for 3 consecutive months
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_banking_branch_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Branch Network Optimization & Demand Forecasting: Branch underperforming — consolidation candidate',
    'Branch underperforming — consolidation candidate'
  );

ALTER ALERT APP.UNDERPERFORM_ALERT RESUME;

-- Alert: DEMAND_SURGE_ALERT
CREATE OR REPLACE ALERT APP.DEMAND_SURGE_ALERT
  WAREHOUSE = BRANCH_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Branch demand exceeding capacity — expansion needed'
IF (EXISTS (
  SELECT 1 FROM CURATED.BRANCH_PERFORMANCE
  WHERE 1=1 -- Condition: FORECAST_DEMAND > 120% of current capacity
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_philippines_banking_branch_EMAIL_INT',
    'jonathan.asvestis@snowflake.com',
    '[ALERT] Branch Network Optimization & Demand Forecasting: Branch demand exceeding capacity — expansion needed',
    'Branch demand exceeding capacity — expansion needed'
  );

ALTER ALERT APP.DEMAND_SURGE_ALERT RESUME;

