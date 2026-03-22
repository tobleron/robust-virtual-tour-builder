import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'node:fs/promises';
import { setupAIObservability } from './ai-helper';
import {
  loadProjectZipAndWait,
  resetClientState,
  waitForBuilderShellReady,
  setupAuthentication,
} from './e2e-helpers';
import { getBudgetConfig } from '../../scripts/runtime-budget-config.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');

const METRICS_PATH = path.resolve('artifacts/perf-budget-metrics.json');

const { budgets, presetName } = getBudgetConfig();
const budgetMetrics: Record<string, unknown> = {};

async function installLongTaskProbe(page) {
  await page.evaluate(() => {
    (window as any).__perfLongTasks = [];
    if (typeof PerformanceObserver === 'undefined') return;

    const observer = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (entry.duration > 50) {
          (window as any).__perfLongTasks.push(entry.duration);
        }
      }
    });
    observer.observe({ entryTypes: ['longtask'] });
  });
}

async function getLongTaskCount(page) {
  return page.evaluate(() => ((window as any).__perfLongTasks || []).length);
}

async function getHeapUsage(page) {
  return page.evaluate(() => {
    const mem = (performance as any).memory;
    return mem?.usedJSHeapSize ?? 0;
  });
}

test.describe.serial('@budget Runtime Budgets', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await page.route('**/images/image.jpg', async (route) => {
      await route.fulfill({
        status: 200,
        path: path.join(FIXTURES_DIR, 'image.jpg'),
        contentType: 'image/jpeg',
      });
    });
    await page.route('**/api/project/import', async (route) => {
      const scenes = [];
      for (let i = 0; i < 120; i++) {
        const name = `Imported Scene ${i}`;
        const next = `Imported Scene ${(i + 1) % 120}`;
        scenes.push({
          id: `import-${i}`,
          name,
          file: 'images/image.jpg',
          hotspots: [{
            linkId: `l-${i}`,
            yaw: 0,
            pitch: 0,
            target: next,
            isAutoForward: false, // Link-level auto-forward (new architecture)
          }],
          category: 'outdoor',
          floor: 'ground',
          label: '',
          isAutoForward: false, // Scene-level (legacy, will be migrated to hotspots)
        });
      }

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          sessionId: 'budget-import-session',
          projectData: {
            tourName: 'Budget Import Tour',
            scenes,
          },
        }),
      });
    });

    // Set up authentication and reset client state
    await setupAuthentication(page, 'dev-token');
    await resetClientState(page, { authToken: 'dev-token' });
    await page.goto('/builder');
    await waitForBuilderShellReady(page);
    await page.waitForFunction(
      () => typeof (window as any).store?.loadProject === 'function',
      undefined,
      { timeout: 30000 },
    );
    await installLongTaskProbe(page);
  });

  test('rapid navigation budget', async ({ page }) => {
    test.setTimeout(180000);
    await page.evaluate(() => {
      const scenes = [];
      for (let i = 0; i < 80; i++) {
        scenes.push({
          id: `budget-scene-${i}`,
          name: `Budget Scene ${i}`,
          label: `Budget Scene ${i}`,
          file: 'images/image.jpg',
          hotspots: [],
          quality: { score: 9.2, stats: { avgLuminance: 125 } },
          colorGroup: String(i % 5),
        });
      }
      (window as any).store.loadProject({
        id: 'budget-nav-project',
        tourName: 'Budget Navigation Project',
        scenes,
      });
    });

    await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 30000 });

    const memInitial = await getHeapUsage(page);
    const timings: number[] = [];
    for (let i = 0; i < 20; i++) {
      const target = (i + 1) % 15;
      await page.evaluate((idx) => {
        const sidebar = document.querySelector('.sidebar-content') as HTMLElement | null;
        if (sidebar) sidebar.scrollTop = idx * 72;
      }, target);
      await page.waitForTimeout(700);

      const startedAt = Date.now();
      const targetSceneButton = page.getByRole('button', { name: `Select scene Budget Scene ${target}`, exact: true });
      await expect(targetSceneButton).toBeVisible({ timeout: 7000 });
      await targetSceneButton.click();
      await page.waitForFunction((idx) => (window as any).__RE_STATE__?.activeIndex === idx, target, {
        timeout: 7000,
      });
      timings.push(Date.now() - startedAt);
    }

    const memFinal = await getHeapUsage(page);
    const sorted = [...timings].sort((a, b) => a - b);
    const p95 = sorted[Math.floor(sorted.length * 0.95) - 1] ?? sorted[sorted.length - 1];
    const longTaskCount = await getLongTaskCount(page);
    const memoryGrowthRatio = memInitial > 0 ? memFinal / memInitial : 1;

    budgetMetrics.rapidNavigation = {
      samples: timings.length,
      p95Ms: p95,
      longTaskCount,
      memoryGrowthRatio,
      memInitial,
      memFinal,
    };

    expect(p95).toBeLessThanOrEqual(budgets.maxRapidNavigationP95Ms);
    expect(longTaskCount).toBeLessThanOrEqual(budgets.maxRapidNavigationLongTasks);
    expect(memoryGrowthRatio).toBeLessThanOrEqual(
      budgets.maxRapidNavigationMemoryGrowthRatio,
    );
  });

  test('bulk upload latency budget', async ({ page }) => {
    test.setTimeout(180000);
    const artifactPath = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');
    const fixturePath = path.join(FIXTURES_DIR, 'tour.vt.zip');
    const importPath = await fs
      .access(artifactPath)
      .then(() => artifactPath)
      .catch(() => fixturePath);

    const startedAt = Date.now();
    await loadProjectZipAndWait(page, importPath, 60000);

    await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 90000 });
    await page.waitForFunction(() => ((window as any).__RE_STATE__?.sceneOrder?.length ?? 0) > 0, {
      timeout: 30000,
    });
    const latencyMs = Date.now() - startedAt;
    const longTaskCount = await getLongTaskCount(page);
    const sceneCount = await page.evaluate(() => (window as any).__RE_STATE__?.sceneOrder?.length ?? 0);

    budgetMetrics.bulkUpload = {
      importedScenes: sceneCount,
      latencyMs,
      longTaskCount,
    };

    expect(sceneCount).toBeGreaterThan(0);
    expect(latencyMs).toBeLessThanOrEqual(budgets.maxBulkUploadLatencyMs);
  });

  test('long simulation session budget', async ({ page }) => {
    test.setTimeout(240000);
    await page.evaluate(() => {
      const scenes = [];
      for (let i = 0; i < 12; i++) {
        const current = `Sim Budget ${i}`;
        const next = `Sim Budget ${(i + 1) % 12}`;
        scenes.push({
          id: `sim-budget-${i}`,
          name: current,
          label: current,
          file: 'images/image.jpg',
          hotspots: [{ linkId: `sim-${i}`, yaw: 0, pitch: 0, target: next }],
          quality: { score: 9.0, stats: { avgLuminance: 120 } },
          colorGroup: String(i % 4),
        });
      }
      (window as any).store.loadProject({
        id: 'sim-budget-project',
        tourName: 'Simulation Budget Tour',
        scenes,
      });
    });

    await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 60000 });

    const memInitial = await getHeapUsage(page);
    const simButton = page.getByRole('button', { name: /Tour Preview/i });
    await expect(simButton).toBeVisible({ timeout: 30000 });
    await simButton.click();

    const visited = new Set<number>();
    const sessionStart = Date.now();
    while (Date.now() - sessionStart < 45000) {
      const activeIndex = await page.evaluate(() => (window as any).__RE_STATE__?.activeIndex ?? -1);
      visited.add(activeIndex);
      if (activeIndex >= 0) {
        const nextIndex = await page.evaluate(() => {
          const state = (window as any).__RE_STATE__;
          const next = ((state?.activeIndex ?? 0) + 1) % 12;
          const nextLabel = `Sim Budget ${next}`;
          const candidates = Array.from(document.querySelectorAll('.scene-item h4')) as HTMLElement[];
          const target = candidates.find((el) => (el.textContent || '').trim() === nextLabel);
          target?.click();
          return next;
        });
        await page
          .waitForFunction((idx) => (window as any).__RE_STATE__?.activeIndex === idx, nextIndex, {
            timeout: 2500,
          })
          .catch(() => undefined);
      }
      await page.waitForTimeout(1500);
    }

    const stopButton = page.getByRole('button', { name: /Stop Tour Preview/i });
    if (await stopButton.isVisible()) {
      await stopButton.click();
    }

    const memFinal = await getHeapUsage(page);
    const longTaskCount = await getLongTaskCount(page);
    const memoryGrowthRatio = memInitial > 0 ? memFinal / memInitial : 1;

    budgetMetrics.longSimulation = {
      durationMs: Date.now() - sessionStart,
      distinctActiveScenes: [...visited].filter((x) => x >= 0).length,
      longTaskCount,
      memoryGrowthRatio,
      memInitial,
      memFinal,
    };

    expect([...visited].filter((x) => x >= 0).length).toBeGreaterThanOrEqual(
      budgets.minSimulationDistinctSceneSwitches,
    );
    expect(longTaskCount).toBeLessThanOrEqual(budgets.maxSimulationLongTasks);
    expect(memoryGrowthRatio).toBeLessThanOrEqual(
      budgets.maxSimulationMemoryGrowthRatio,
    );
  });

  test.afterAll(async () => {
    await fs.mkdir(path.dirname(METRICS_PATH), { recursive: true });
    await fs.writeFile(
      METRICS_PATH,
      JSON.stringify(
        {
          generatedAt: new Date().toISOString(),
          ...budgetMetrics,
        },
        null,
        2,
      ),
      'utf8',
    );
  });
});
