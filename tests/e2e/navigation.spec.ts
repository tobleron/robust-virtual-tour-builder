import { test, expect } from '@playwright/test';
import path from 'path';
import { setupAIObservability } from './ai-helper';
import { loadProjectZipAndWait } from './e2e-helpers';

const ZIP_LINKED_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');
const ZIP_SIM_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

async function sceneIdAtIndex(page, index) {
  return await page.evaluate((idx) => {
    // @ts-ignore
    const state = window.store?.state;
    const sceneOrder = state?.sceneOrder ?? [];
    return sceneOrder[idx] ?? null;
  }, index);
}

async function waitForActiveIndex(page, expectedIndex, timeout = 30000) {
  await page.waitForFunction(
    (target) => {
      // @ts-ignore
      const state = window.store?.state;
      return state?.activeIndex === target;
    },
    expectedIndex,
    { timeout },
  );
}

test.describe('Navigation Engine', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await page.goto('/');
  });

  test('should navigate between scenes via hotspot', async ({ page }) => {
    test.setTimeout(90000);
    await loadProjectZipAndWait(page, ZIP_LINKED_PATH, 30000);

    const firstSceneId = await sceneIdAtIndex(page, 0);
    await expect(page.locator(`.scene-item[data-scene-id="${firstSceneId}"]`).first()).toBeVisible({ timeout: 20000 });

    // Wait for viewer ready
    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });

    // Wait for React hotspot layer to render
    await page.waitForSelector('#react-hotspot-layer', { state: 'visible', timeout: 45000 });
    await page.waitForTimeout(1000);

    const initialLabel = await page.locator('#v-scene-persistent-label').textContent();

    // Click the first hotspot
    const hotspot = page.locator('[id^="hs-react-"]').first();
    await expect(hotspot).toBeVisible({ timeout: 10000 });
    await hotspot.click();

    await page.waitForFunction(
      (oldLabel) => {
        const dom = document.getElementById('v-scene-persistent-label');
        return dom && dom.textContent !== oldLabel;
      },
      initialLabel,
      { timeout: 30000 },
    );
  });

  test('should run simulation mode and auto-navigate', async ({ page, browserName }) => {
    test.skip(browserName === 'webkit', 'Simulation mode relies on MediaRecorder which is flaky in headless WebKit');
    test.setTimeout(180000);
    await loadProjectZipAndWait(page, ZIP_SIM_PATH, 60000);

    const deterministicStartSceneId = await sceneIdAtIndex(page, 0);
    const deterministicStartRow = page.locator(`.scene-item[data-scene-id="${deterministicStartSceneId}"]`).first();
    await expect(deterministicStartRow).toBeVisible({ timeout: 20000 });
    await deterministicStartRow.click();
    await waitForActiveIndex(page, 0, 20000);

    // Wait for UI to settle
    await page.waitForTimeout(2000);

    // Start simulation by clicking the Tour Preview button in utility bar
    const simBtn = page.locator('#viewer-utility-bar button[aria-label="Tour Preview"]');
    await expect(simBtn).toBeVisible({ timeout: 10000 });
    await simBtn.click();

    // Verify simulation is running - processing card appears in sidebar
    const processingCard = page.locator('.sidebar-processing-card');
    await expect(processingCard).toBeVisible({ timeout: 15000 });

    // Stop Simulation
    await simBtn.click();
    await expect(processingCard).toBeHidden({ timeout: 10000 });
  });

  test('should rotate camera 180 degrees when returning to a hub scene', async ({ page }) => {
    test.setTimeout(120000);
    await loadProjectZipAndWait(page, ZIP_LINKED_PATH, 30000);

    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });
    await page.waitForSelector('#react-hotspot-layer', { state: 'visible', timeout: 45000 });
    await page.waitForTimeout(1000);

    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store.state;
      const activeIdx = state.activeIndex;
      const sceneOrder = state.sceneOrder;
      const activeId = sceneOrder[activeIdx];
      const entry = state.inventory[activeId];
      if (entry && entry.scene.hotspots && entry.scene.hotspots.length > 0) {
        return {
          id: activeId,
          yaw: entry.scene.hotspots[0].yaw
        };
      }
      return null;
    });

    if (!hotspotData) {
      test.skip(true, 'No hotspots found in start scene of fixture');
      return;
    }

    const hotspotYaw = hotspotData.yaw;

    // Navigate to Scene 2
    const hotspot = page.locator('[id^="hs-react-"]').first();
    await hotspot.click();

    // Wait for scene change (active index change)
    await waitForActiveIndex(page, 1, 30000);
    await page.waitForTimeout(2000);

    // Navigate back to the original scene by clicking scene list
    await page.locator('.scene-item').first().click();
    await waitForActiveIndex(page, 0, 30000);

    // Wait for transition and stabilization
    await page.waitForTimeout(3000);

    // Verify final yaw is approximately hotspotYaw + 180 (hub scene return logic)
    const finalYaw = await page.evaluate(() => {
      // @ts-ignore
      return window.pannellumViewer.getYaw();
    });

    const expectedYaw = ((hotspotYaw + 180 + 180) % 360) - 180; // Normalize to [-180, 180]

    // Allow for small floating point differences
    const diff = Math.abs(finalYaw - expectedYaw);
    const normalizedDiff = diff > 180 ? 360 - diff : diff;

    expect(normalizedDiff).toBeLessThan(10); // 10 degrees tolerance for E2E
  });
});
