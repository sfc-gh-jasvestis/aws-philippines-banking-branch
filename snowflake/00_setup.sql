-- Generated from generator/demo_specs/aws-philippines-banking-branch.json
-- Regenerate with: python3 generator/gen_repo_docs.py aws-philippines-banking-branch
-- This is the schema that is actually deployed for PH_BANKING_BRANCH.

-- PH_BANKING_BRANCH  (Branch Network Optimization & Demand Forecasting)
-- generated from generator/demo_specs/aws-philippines-banking-branch.json - do not hand-edit
CREATE DATABASE IF NOT EXISTS PH_BANKING_BRANCH;
CREATE SCHEMA IF NOT EXISTS PH_BANKING_BRANCH.RAW;
CREATE SCHEMA IF NOT EXISTS PH_BANKING_BRANCH.CURATED;
CREATE SCHEMA IF NOT EXISTS PH_BANKING_BRANCH.APP;
USE DATABASE PH_BANKING_BRANCH;

-- 5 real regions; entity names carry their region so the two always agree
