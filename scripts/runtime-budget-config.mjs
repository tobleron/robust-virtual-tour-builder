const BUDGET_PRESETS = {
  baseline: {
    maxRapidNavigationP95Ms: 1500,
    maxRapidNavigationLongTasks: 15,
    maxRapidNavigationMemoryGrowthRatio: 2.2,
    maxBulkUploadLatencyMs: 90000,
    minSimulationDistinctSceneSwitches: 2,
    maxSimulationLongTasks: 30,
    maxSimulationMemoryGrowthRatio: 2.2,
  },
  sandbox: {
    maxRapidNavigationP95Ms: 1600,
    maxRapidNavigationLongTasks: 25,
    maxRapidNavigationMemoryGrowthRatio: 2.8,
    maxBulkUploadLatencyMs: 120000,
    minSimulationDistinctSceneSwitches: 2,
    maxSimulationLongTasks: 40,
    maxSimulationMemoryGrowthRatio: 3.0,
  },
};

function parseNumber(value, fallback) {
  if (value == null || value === '') {
    return fallback;
  }
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function resolveBudgetPresetName(env = process.env) {
  const override = env.BUDGET_PRESET;
  if (override) {
    const normalized = override.trim().toLowerCase();
    if (normalized === 'baseline' || normalized === 'sandbox') {
      return normalized;
    }
  }

  return env.NODE_ENV?.toLowerCase() === 'production' ? 'baseline' : 'sandbox';
}

export function getBudgetConfig(env = process.env) {
  const presetName = resolveBudgetPresetName(env);
  const preset = BUDGET_PRESETS[presetName] ?? BUDGET_PRESETS.sandbox;

  const budgets = {
    maxRapidNavigationP95Ms: parseNumber(env.BUDGET_MAX_RAPID_NAV_P95_MS, preset.maxRapidNavigationP95Ms),
    maxRapidNavigationLongTasks: parseNumber(env.BUDGET_MAX_RAPID_NAV_LONG_TASKS, preset.maxRapidNavigationLongTasks),
    maxRapidNavigationMemoryGrowthRatio: parseNumber(env.BUDGET_MAX_RAPID_NAV_MEMORY_RATIO, preset.maxRapidNavigationMemoryGrowthRatio),
    maxBulkUploadLatencyMs: parseNumber(env.BUDGET_MAX_BULK_UPLOAD_MS, preset.maxBulkUploadLatencyMs),
    minSimulationDistinctSceneSwitches: parseNumber(env.BUDGET_MIN_SIMULATION_DISTINCT_SCENES, preset.minSimulationDistinctSceneSwitches),
    maxSimulationLongTasks: parseNumber(env.BUDGET_MAX_SIMULATION_LONG_TASKS, preset.maxSimulationLongTasks),
    maxSimulationMemoryGrowthRatio: parseNumber(env.BUDGET_MAX_SIMULATION_MEMORY_RATIO, preset.maxSimulationMemoryGrowthRatio),
  };

  return { presetName, budgets, preset };
}

export const PRESET_DETAILS = Object.freeze({
  baseline: BUDGET_PRESETS.baseline,
  sandbox: BUDGET_PRESETS.sandbox,
});
