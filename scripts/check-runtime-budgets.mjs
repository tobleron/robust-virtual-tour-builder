#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';

const METRICS_PATH = path.resolve('artifacts/perf-budget-metrics.json');

const budgets = {
  maxRapidNavigationP95Ms: Number(process.env.BUDGET_MAX_RAPID_NAV_P95_MS ?? 1500),
  maxRapidNavigationLongTasks: Number(process.env.BUDGET_MAX_RAPID_NAV_LONG_TASKS ?? 15),
  maxRapidNavigationMemoryGrowthRatio: Number(
    process.env.BUDGET_MAX_RAPID_NAV_MEMORY_RATIO ?? 2.5,
  ),
  maxBulkUploadLatencyMs: Number(process.env.BUDGET_MAX_BULK_UPLOAD_MS ?? 90000),
  minSimulationDistinctSceneSwitches: Number(
    process.env.BUDGET_MIN_SIMULATION_DISTINCT_SCENES ?? 2,
  ),
  maxSimulationLongTasks: Number(process.env.BUDGET_MAX_SIMULATION_LONG_TASKS ?? 30),
  maxSimulationMemoryGrowthRatio: Number(
    process.env.BUDGET_MAX_SIMULATION_MEMORY_RATIO ?? 2.2,
  ),
};

function assertBudget(condition, message, failures) {
  if (!condition) failures.push(message);
}

async function main() {
  const raw = await fs.readFile(METRICS_PATH, 'utf8');
  const metrics = JSON.parse(raw);
  const failures = [];

  assertBudget(
    metrics.rapidNavigation?.p95Ms <= budgets.maxRapidNavigationP95Ms,
    `rapidNavigation.p95Ms ${metrics.rapidNavigation?.p95Ms} > ${budgets.maxRapidNavigationP95Ms}`,
    failures,
  );
  assertBudget(
    metrics.rapidNavigation?.longTaskCount <= budgets.maxRapidNavigationLongTasks,
    `rapidNavigation.longTaskCount ${metrics.rapidNavigation?.longTaskCount} > ${budgets.maxRapidNavigationLongTasks}`,
    failures,
  );
  assertBudget(
    metrics.rapidNavigation?.memoryGrowthRatio <=
      budgets.maxRapidNavigationMemoryGrowthRatio,
    `rapidNavigation.memoryGrowthRatio ${metrics.rapidNavigation?.memoryGrowthRatio} > ${budgets.maxRapidNavigationMemoryGrowthRatio}`,
    failures,
  );
  assertBudget(
    metrics.bulkUpload?.latencyMs <= budgets.maxBulkUploadLatencyMs,
    `bulkUpload.latencyMs ${metrics.bulkUpload?.latencyMs} > ${budgets.maxBulkUploadLatencyMs}`,
    failures,
  );
  assertBudget(
    metrics.longSimulation?.distinctActiveScenes >=
      budgets.minSimulationDistinctSceneSwitches,
    `longSimulation.distinctActiveScenes ${metrics.longSimulation?.distinctActiveScenes} < ${budgets.minSimulationDistinctSceneSwitches}`,
    failures,
  );
  assertBudget(
    metrics.longSimulation?.longTaskCount <= budgets.maxSimulationLongTasks,
    `longSimulation.longTaskCount ${metrics.longSimulation?.longTaskCount} > ${budgets.maxSimulationLongTasks}`,
    failures,
  );
  assertBudget(
    metrics.longSimulation?.memoryGrowthRatio <=
      budgets.maxSimulationMemoryGrowthRatio,
    `longSimulation.memoryGrowthRatio ${metrics.longSimulation?.memoryGrowthRatio} > ${budgets.maxSimulationMemoryGrowthRatio}`,
    failures,
  );

  console.log('[budget][runtime] Metrics');
  console.log(JSON.stringify(metrics, null, 2));

  if (failures.length > 0) {
    for (const failure of failures) {
      console.error(`[budget][runtime][FAIL] ${failure}`);
    }
    process.exit(1);
  }

  console.log('[budget][runtime][PASS] Runtime budgets are within limits.');
}

main().catch((err) => {
  console.error('[budget][runtime][ERROR]', err);
  process.exit(1);
});

