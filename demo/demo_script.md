# Branch Network Optimization & Demand Forecasting

**Philippines - Banking & Insurance**
Use case: Branch Network Optimization

> Philippine banks operate 12,000+ branches serving 55M banked Filipinos — Snowflake uses H3 geospatial + ST_WITHIN to identify underserved areas, ML.FORECAST to predict branch demand, and optimize branch network expansion.

## Why Snowflake

Snowflake combines AWS Location Service data with H3 geospatial indexing and ML.FORECAST to optimize Philippine bank branch networks — identifying underserved areas, predicting demand, and recommending optimal new branch locations

- **H3 geospatial + ST_WITHIN for catchment analysis** - Only demo using Snowflake H3 functions for bank branch location optimization
- **ML.FORECAST for branch demand prediction** - Native forecasting for branch transaction volumes without SageMaker
- **ML.CLASSIFICATION for branch viability scoring** - Predicts whether proposed branch will be profitable within 2 years
- **Competitor density overlay** - 4,200 competitor branches mapped and analyzed via geospatial SQL
- **Philippine banking geography** - 7,641 islands, 55M banked/51M unbanked, with BSP branch requirements
- **Location Service foot traffic integration** - Real foot traffic data enriching branch analytics

## What is deployed

| | |
|---|---|
| Database | `PH_BANKING_BRANCH` |
| Service | `PH_BANKING_BRANCH_APP` |
| Compute pool | `SEA_DEMOS_PHILIPPINES_POOL` |
| Dimension table | `RAW.BSP_BANKING_DATA` (20 rows) |
| Fact table | `RAW.TRANSACTIONS` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | PHP (₱) |

Regions in play: Metro Manila, Cebu, Davao, Pampanga, Iloilo
Segments: Metro Flagship, Provincial Branch, In-Store Kiosk, Micro Branch

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh PH_BANKING_BRANCH
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Branch Revenue | `₱4.2B` | total across Bsp Banking Data |
| Digital Adoption | `67%` | average per event |
| NPS Score | `72` | average per event |
| Branches Active | `847` | total across Bsp Banking Data |
| Mobile Banking Users | `4.2M` | total across Bsp Banking Data |
| Branch-to-Digital Shift | `+14%` | average per event |
| Cost per Transaction | `₱42` | total across Bsp Banking Data |


## Demo flow

1. Executive Cockpit
2. Coverage Analysis
3. Demand & ROI
4. Ask AI
5. Architecture & Data

## Talking points

- **850 branches** - serving 4.2M customers nationwide
- **124 branches** - underperforming (negative ROI)
- **15 provinces** - with 500K+ population and zero branch presence
- **16 of 20** - proposed branches predicted profitable within 2 years
- **62%** - of Filipino population within 5km of a bank branch
- **₱18M** - average annual revenue per branch

## Business impact

- Philippine banking sector assets reached ₱22.4 trillion in 2023 (BSP)
- 51 million Filipino adults remain unbanked — largest financial inclusion gap in ASEAN (BSP Financial Inclusion Survey)
- Geospatial analytics improves branch location ROI by 30-50% (McKinsey Banking)
- Digital-first branch formats reduce operating costs 40-60% vs traditional branches (Deloitte Banking)

---
Generated from `generator/demo_specs/aws-philippines-banking-branch.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-philippines-banking-branch` instead.
