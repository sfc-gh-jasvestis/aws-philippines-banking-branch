-- ============================================================================
-- Branch Network Optimization & Demand Forecasting
-- Philippine banks operate 12,000+ branches serving 55M banked Filipinos — Snowflake uses H3 geospatial + ST_WITHIN to identify underserved areas, ML.FORECAST to predict branch demand, and optimize branch network expansion.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS BRANCH_NETWORK;
CREATE WAREHOUSE IF NOT EXISTS BRANCH_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE BRANCH_NETWORK;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE BRANCH_WH;
