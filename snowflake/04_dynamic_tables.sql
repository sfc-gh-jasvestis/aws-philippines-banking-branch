-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Branch Network Optimization & Demand Forecasting
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA CURATED;

-- BRANCH_PERFORMANCE: Branch-level performance with profitability and utilization
-- Source: BRANCHES, TRANSACTIONS, BRANCH_FINANCIALS
CREATE OR REPLACE DYNAMIC TABLE CURATED.BRANCH_PERFORMANCE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BRANCH_WH
AS
SELECT * FROM RAW.BRANCHES;
-- TODO: Replace with actual join/aggregation logic per demo

-- CATCHMENT_ANALYSIS: Population and competitor density within H3 hexagons
-- Source: BRANCHES, COMPETITOR_BRANCHES, POPULATION_GRID
CREATE OR REPLACE DYNAMIC TABLE CURATED.CATCHMENT_ANALYSIS
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BRANCH_WH
AS
SELECT * FROM RAW.BRANCHES;
-- TODO: Replace with actual join/aggregation logic per demo

-- DEMAND_TIMESERIES: Daily transaction volumes by branch for ML.FORECAST
-- Source: TRANSACTIONS, BRANCHES
CREATE OR REPLACE DYNAMIC TABLE CURATED.DEMAND_TIMESERIES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BRANCH_WH
AS
SELECT * FROM RAW.TRANSACTIONS;
-- TODO: Replace with actual join/aggregation logic per demo

-- EXPANSION_CANDIDATES: Underserved areas ranked by potential demand and ROI
-- Source: POPULATION_GRID, COMPETITOR_BRANCHES, CATCHMENT_ANALYSIS
CREATE OR REPLACE DYNAMIC TABLE CURATED.EXPANSION_CANDIDATES
  TARGET_LAG = '5 minutes'
  WAREHOUSE = BRANCH_WH
AS
SELECT * FROM RAW.POPULATION_GRID;
-- TODO: Replace with actual join/aggregation logic per demo

