# Philippines Bank Branch Operations

**Philippines - Retail Bank Branch Network**
Use case: Branch incidents, queue-wait service levels, cash and ATM controls

> Operations monitoring for 40 branches of a fictional Philippine retail bank in 5 cities: dynamic tables, a holdout-evaluated failed-transaction classifier, an incident-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile transactions, incidents, failed-transaction incidents, queue SLA breaches and cash audit compliance from RAW branch data, with checks in `run_core.py`
- **Failed-transaction classification** gives a holdout-evaluated next-7-day probability per branch
- **Incident forecast** projects 14 days of network-wide incident volume with prediction intervals, for field-support staffing
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live transactions**: a native simulator (Snowflake only) or Firehose, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.BRANCHES` (40 rows) |
| Fact table | `RAW.BRANCH_DAILY` (3,600 branch-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `INCIDENT_SUMMARY`, `TREND_ANALYSIS` |
| ML | `ML.FAILURE_RISK_SCORES`, `ML.FAILURE_RISK_HOLDOUT_METRICS`, `ML.INCIDENT_FORECAST`, `ML.ATM_DOWNTIME_ANOMALIES` |

Cities: Quezon City, Cebu City, Davao City, Iloilo City, Cagayan de Oro (PHP).
Formats: Full-service branch, Mall branch, Business centre, Micro branch, Off-site ATM hub.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| Incident-Free Transaction Rate | 99.98% |
| Incidents Raised | 586 |
| Failed-Transaction Incidents | 163 |
| Incident Failure Rate | 27.8% |
| SLA Breaches | 86 |
| Value Processed (PHP M) | 25,115 |
| Transactions Processed | 3,328,765 |
| Cash Audit Compliance | 77.9% |
| Branches Monitored | 40 |
| Branch Control Coverage | 61.6% |
| Control Documents Pending | 29 |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily incidents against failed-transaction incidents, incidents and failures by incident type, branch table
2. Predictive: holdout metrics, risk bands, 14-day incident forecast, ATM downtime anomalies
3. Controls: cash audit compliance, branch control coverage and pending documents, audit compliance against failed transactions, then generate the action memo
4. Live Transactions: run `CALL APP.SIMULATE_TRANSACTIONS(20)` (Snowflake only) or `python aws/publish_transactions.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_INCIDENT_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- 99.98% of transactions are untouched by an incident; the 586 incidents are where branch operations time goes, and 27.8% of them end in failed transactions.
- Queue overflow produces the most failed-transaction incidents (54 of 143). Area power interruptions hit every branch in a city at once and always resolve.
- The risk model is evaluated on a time-based holdout: precision 0.43 and recall 0.40 at 0.5, against a 0.185 base rate. Present it as triage, not a verdict.
- Area power interruptions are excluded from model training, because they are not branch-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
