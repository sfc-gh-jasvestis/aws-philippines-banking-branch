import { NextResponse } from 'next/server';
import { executeQuery } from '@/lib/snowflake';
import { demoPlatform } from '@/lib/platform';

export const dynamic = 'force-dynamic';

// Only these fixed, read-only queries can run. The model never writes SQL; it
// only summarises rows returned here, so every answer is traceable to data.
const INTENTS: Record<string, { match: RegExp; sql: string }> = {
  branches: {
    match: /fail|branch|city|worst|highest|breach/i,
    sql: `SELECT ENTITY_ID, ENTITY_NAME, REGION, CATEGORY, INCIDENT_COUNT, FAILED_COUNT, SLA_BREACH_COUNT, ROUND(INCIDENT_FAILURE_PCT, 1) AS INCIDENT_FAILURE_PCT
FROM CURATED.PERFORMANCE_SUMMARY
QUALIFY DENSE_RANK() OVER (ORDER BY FAILED_COUNT DESC) <= 3
ORDER BY FAILED_COUNT DESC, INCIDENT_COUNT DESC`,
  },
  types: {
    match: /type|reason|cause|why|incident/i,
    sql: `SELECT INCIDENT_TYPE, INCIDENT_COUNT, FAILED_COUNT, SLA_BREACH_COUNT, ROUND(INCIDENT_FAILURE_PCT, 1) AS INCIDENT_FAILURE_PCT
FROM CURATED.INCIDENT_SUMMARY ORDER BY FAILED_COUNT DESC LIMIT 8`,
  },
  kpis: {
    match: /.*/,
    sql: `SELECT TITLE, DISPLAY, SOURCE_WATERMARK FROM CURATED.KPI_SUMMARY ORDER BY SORT_ORDER`,
  },
};

const DEFINITIONS =
  'Incident-free transaction rate = transactions not touched by an incident / transactions processed. Incident failure rate = failed transactions / incidents raised. ' +
  'An SLA breach is a failed-transaction day on which the queue wait SLA was missed. Area power interruption incidents are city-wide and always resolve without a failed transaction. ' +
  'Values are in PHP; branches are fictional sites in 5 Philippine cities. All data is synthetic demo data.';

// provider 'cortex' = Snowflake AI_COMPLETE; 'bedrock' = Amazon Bedrock Claude
// via the external-access UDF APP.BEDROCK_GENERATE (aws/setup_aws.py).
async function summarise(question: string, rows: unknown[], provider: 'cortex' | 'bedrock' = 'cortex'): Promise<string> {
  const prompt =
    'You are a branch operations analyst at a fictional Philippine retail bank. Answer ONLY from the JSON rows and definitions below. ' +
    'If the rows do not answer the question, say so. Do not invent numbers. Keep it under 120 words.\n' +
    `Definitions: ${DEFINITIONS}\nRows: ${JSON.stringify(rows)}\nQuestion: ${question}`;
  const out = await executeQuery<{ R: string }>(
    provider === 'bedrock' ? 'SELECT APP.BEDROCK_GENERATE(?) AS R' : `SELECT AI_COMPLETE('claude-sonnet-4-5', ?) AS R`,
    [prompt],
  );
  const raw = String(out[0]?.R ?? '').trim();
  // AI_COMPLETE returns a JSON string literal; decode it when present.
  try {
    const parsed = JSON.parse(raw);
    return typeof parsed === 'string' ? parsed : raw;
  } catch {
    return raw;
  }
}

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const question = typeof body?.question === 'string' ? body.question.trim().slice(0, 2000) : '';
  const memo = body?.mode === 'memo';
  if (!memo && !question) return NextResponse.json({ error: 'Question required' }, { status: 400 });

  try {
    if (memo) {
      const provider = demoPlatform() === 'aws' ? 'bedrock' : 'cortex';
      const [kpis, branches, types, risk, bands] = await Promise.all([
        executeQuery(INTENTS.kpis.sql),
        executeQuery(INTENTS.branches.sql),
        executeQuery(INTENTS.types.sql),
        executeQuery(`SELECT ENTITY_ID, ROUND(FAILURE_PROB_7D, 2) AS FAILURE_PROB_7D, RISK_BAND
FROM ML.FAILURE_RISK_SCORES ORDER BY FAILURE_PROB_7D DESC LIMIT 5`),
        executeQuery(`SELECT RISK_BAND, COUNT(*) AS BRANCHES FROM ML.FAILURE_RISK_SCORES GROUP BY RISK_BAND`),
      ]);
      const rows = { kpis, topFailedBranches: branches, incidentTypes: types, top5ByRisk: risk, branchesPerRiskBand: bands };
      const answer = await summarise(
        'Draft a short action memo for the Head of Branch Operations with 3 prioritised actions, citing the figures.',
        [rows],
        provider,
      );
      return NextResponse.json({ answer, sources: rows, provider: provider === 'bedrock' ? 'Amazon Bedrock (Claude Sonnet 4.5)' : 'Snowflake Cortex AI_COMPLETE (claude-sonnet-4-5)', draft: true, synthetic: true });
    }
    const key = Object.keys(INTENTS).find((k) => INTENTS[k].match.test(question))!;
    const rows = await executeQuery(INTENTS[key].sql);
    const answer = await summarise(question, rows);
    return NextResponse.json({ answer, sql: INTENTS[key].sql, sources: rows, synthetic: true });
  } catch (err) {
    console.error('ask route failed', err);
    return NextResponse.json({ error: 'AI service unavailable' }, { status: 503 });
  }
}
