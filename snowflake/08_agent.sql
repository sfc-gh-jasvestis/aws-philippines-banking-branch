-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Branch Network Optimization & Demand Forecasting
-- ============================================================================
USE DATABASE BRANCH_NETWORK;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.BRANCH_INTELLIGENCE_AGENT
  COMMENT = 'Branch Network Optimization & Demand Forecasting AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'BRANCH_NETWORK.APP.BRANCH_NETWORK_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'BRANCH_NETWORK.SEARCH.BSP_BRANCH_SEARCH', TOOL_DESCRIPTION => 'Search documents for Banking & Insurance information')
  )
  SYSTEM_PROMPT = 'You are the Branch Network Intelligence Agent for a Philippine bank with 850 branches competing against BDO (1,400+), BPI (900+), and Metrobank (950+) nationwide.';
