-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Branch Network Optimization & Demand Forecasting
-- Country: PHILIPPINES | Currency: PHP
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- BRANCHES: 850 rows — Bank branch locations with performance data
-- COMPETITOR_BRANCHES: 4,200 rows — Major competitor branch locations (BDO, BPI, Metrobank, Landbank)
-- TRANSACTIONS: 12,000,000 rows — 6 months of branch transaction data
-- POPULATION_GRID: 45,000 rows — Population density by barangay with demographics
-- FOOT_TRAFFIC: 2,800,000 rows — Location Service foot traffic data near branches
-- BRANCH_FINANCIALS: 5,100 rows — Monthly branch P&L and productivity metrics
-- BSP_BANKING_DATA: 82 rows — BSP branch banking statistics by region
