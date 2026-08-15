-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Branch Network Optimization & Demand Forecasting
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.BRANCH_NETWORK_ANALYTICS
  COMMENT = 'Branch performance, geospatial coverage, demand forecasting, and expansion analytics'
AS
  TABLES (
    CURATED.BRANCH_PERFORMANCE AS branch_performance,CURATED.CATCHMENT_ANALYSIS AS catchment_analysis,CURATED.DEMAND_TIMESERIES AS demand_timeseries,CURATED.EXPANSION_CANDIDATES AS expansion_candidates
  );
