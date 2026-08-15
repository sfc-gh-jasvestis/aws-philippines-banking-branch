# Demo Script: Branch Network Optimization & Demand Forecasting
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake combines AWS Location Service data with H3 geospatial indexing and ML.FORECAST to optimize Philippine bank branch networks — identifying underserved areas, predicting demand, and recommending optimal new branch locations"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Conchita Maria Yuchengco** | EVP Branch Banking | React App (SPCS) | Branch profitability, network expansion ROI, market coverage, digital migration |
| **Alejandro Luis Aboitiz** | Network Planning Director | Amazon QuickSight | Location analytics, catchment areas, competitor density, foot traffic patterns |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 7 tables | BRANCHES (850), COMPETITOR_BRANCHES (4200), TRANSACTIONS (12000000), POPULATION_GRID (45000), FOOT_TRAFFIC (2800000), BRANCH_FINANCIALS (5100), BSP_BANKING_DATA (82) |
| **CURATED** | 4 Dynamic Tables | BRANCH_PERFORMANCE, CATCHMENT_ANALYSIS, DEMAND_TIMESERIES, EXPANSION_CANDIDATES |
| **ML** | ML.FORECAST + ML.CLASSIFICATION | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY | Classification + extraction |
| **Search** | Cortex Search | 82 documents indexed |
| **Agent** | BRANCH_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

Philippine banking is a tale of two markets: 55 million banked Filipinos clustered in NCR and Cebu, and 51 million unbanked across provinces. A mid-tier universal bank operates 850 branches but faces a strategic dilemma — 124 branches are losing money while 15 provinces have no bank presence at all. Geospatial intelligence with H3 and demand forecasting with ML.FORECAST reveals exactly where to expand, consolidate, or transform.

---

## Script

### [0:00–0:45] EXECUTIVE COCKPIT

**Show**: Executive Cockpit tab

> "850 branches serving 4.2M customers — average branch generates ₱18M annual revenue."

**Action**: Point at 850 branches on national map

### [0:45–1:30] COVERAGE ANALYSIS

**Show**: Coverage Analysis tab

> "H3 hexagonal analysis: 62% of Filipino population is within 5km of a bank branch."

**Action**: Show H3 coverage heatmap

### [1:30–2:15] DEMAND & ROI

**Show**: Demand & ROI tab

> "ML.FORECAST predicts: Pampanga branches will grow 14% in transactions next year."

**Action**: Show demand forecast for Pampanga

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Conchita asks: 'What's the projected revenue for a branch in San Fernando, Pampanga?'"

**Action**: Type: 'Projected revenue for San Fernando branch?'

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Location Service → H3 aggregation → catchment analysis → ML.FORECAST → expansion scoring."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **H3 geospatial + ST_WITHIN for catchment analysis** — Only demo using Snowflake H3 functions for bank branch location optimization
2. **ML.FORECAST for branch demand prediction** — Native forecasting for branch transaction volumes without SageMaker
3. **ML.CLASSIFICATION for branch viability scoring** — Predicts whether proposed branch will be profitable within 2 years
4. **Competitor density overlay** — 4,200 competitor branches mapped and analyzed via geospatial SQL
5. **Philippine banking geography** — 7,641 islands, 55M banked/51M unbanked, with BSP branch requirements
6. **Location Service foot traffic integration** — Real foot traffic data enriching branch analytics


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM BRANCH_NETWORK.RAW.BRANCHES` → 850
- [ ] `SELECT COUNT(*) FROM BRANCH_NETWORK.RAW.TRANSACTIONS` → 12000000
- [ ] `SELECT COUNT(*) FROM BRANCH_NETWORK.CURATED.BRANCH_PERFORMANCE WHERE ROI_PCT < 0` → 124

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM BRANCH_NETWORK.ML.BRANCH_DEMAND_FORECAST_RESULTS` → >0
- [ ] `SELECT COUNT(*) FROM BRANCH_NETWORK.ML.BRANCH_VIABILITY_RESULTS WHERE PROFITABLE_WITHIN_2Y = TRUE` → 16

### AI/Agent Verification
- [ ] `SELECT COUNT(DISTINCT OPTIMIZATION_CATEGORY) FROM BRANCH_NETWORK.AI.BRANCH_CLASSIFICATION` → 4

