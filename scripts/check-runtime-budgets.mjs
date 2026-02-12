#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';

const METRICS_PATH = path.resolve('artifacts/perf-budget-metrics.json');

import { getBudgetConfig } from './runtime-budget-config.mjs';

const { budgets, presetName } = getBudgetConfig();

function assertBudget(condition, message, failures) {
  if (!condition) failures.push(message);
}

async function main() {
  const raw = await fs.readFile(METRICS_PATH, 'utf8');
  const metrics = JSON.parse(raw);
  const failures = [];

  console.log(`[budget][runtime] Using preset '${presetName}' with thresholds:`);
  console.table(budgets);

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
