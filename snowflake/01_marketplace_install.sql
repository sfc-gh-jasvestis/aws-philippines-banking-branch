-- ============================================================================
-- 01_MARKETPLACE_INSTALL.SQL — Install marketplace data for Branch Network Optimization & Demand Forecasting
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA RAW;

-- Free listings to install from Snowflake Marketplace:
-- Install: Snowflake Public Data (Free)
--   https://app.snowflake.com/marketplace/listing/GZTSZ290BV255

-- Paid listing (mock): SafeGraph Foot Traffic
--   Real data: https://app.snowflake.com/marketplace/listing/GZ2FQZRNJ5Y
--   Using mock table: FOOT_TRAFFIC
CREATE TABLE IF NOT EXISTS RAW.FOOT_TRAFFIC (
  ID INT AUTOINCREMENT, DATA VARIANT, LOADED_AT TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

