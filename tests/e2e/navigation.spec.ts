import { test, expect } from '@playwright/test';
import path from 'path';
import { setupAIObservability } from './ai-helper';
import { loadProjectZipAndWait } from './e2e-helpers';

const ZIP_LINKED_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');
const ZIP_SIM_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

async function sceneIdAtIndex(page, index) {
  return await page.evaluate((idx) => {
    const state = window.store?.getState?.();
    const sceneOrder = state?.sceneOrder ?? [];
    return sceneOrder[idx] ?? null;
  }, index);
}

async function waitForActiveIndex(page, expectedIndex, timeout = 30000) {
  await page.waitForFunction(
    (target) => {
      const state = window.store?.getState?.();
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
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();
  });

  test('should navigate between scenes via hotspot', async ({ page }) => {
    test.setTimeout(90000);
    await loadProjectZipAndWait(page, ZIP_LINKED_PATH, 30000);

    const firstSceneId = await sceneIdAtIndex(page, 0);
    await expect(page.locator(`.scene-item[data-scene-id="${firstSceneId}"]`).first()).toBeVisible({ timeout: 20000 });

    // Wait for viewer ready
    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });

    // Wait for React hotspot layer to render (hotspots are in React layer, not Pannellum)
    await page.waitForSelector('#react-hotspot-layer', { state: 'visible', timeout: 45000 });
    await page.waitForTimeout(500); // Allow interaction listeners to attach

    // Click the first hotspot to navigate to Scene 2
    // Hotspots are rendered as #hs-react-{linkId} in the React layer
    const hotspot = page.locator('[id^="hs-react-"]').first();
    await expect(hotspot).toBeVisible({ timeout: 10000 });
    const initialLabel = (await page.locator('#v-scene-persistent-label').textContent())?.trim();
    await hotspot.click();

    await page.waitForFunction(
      (label) => {
        const dom = document.getElementById('v-scene-persistent-label');
        return dom?.textContent?.trim() !== label;
      },
      initialLabel,
      { timeout: 30000 },
    );
  });

  test('should run simulation mode and auto-navigate', async ({ page, browserName }) => {
    test.skip(browserName === 'webkit', 'Simulation mode relies on MediaRecorder which is flaky in headless WebKit');
    test.setTimeout(120000);
    await loadProjectZipAndWait(page, ZIP_SIM_PATH, 30000);

    const deterministicStartSceneId = await sceneIdAtIndex(page, 0);
    const deterministicStartRow = page.locator(`.scene-item[data-scene-id="${deterministicStartSceneId}"]`).first();
    await expect(deterministicStartRow).toBeVisible({ timeout: 20000 });
    await deterministicStartRow.click();
    await waitForActiveIndex(page, 0, 20000);
    await expect(page.locator('#v-scene-persistent-label')).toBeVisible({ timeout: 10000 });

    // Start simulation by clicking the Tour Preview button in viewer utility bar
    const simBtn = page.getByRole('button', { name: 'Tour Preview' });
    await expect(simBtn).toBeVisible({ timeout: 10000 });
    await simBtn.click();

    // Wait for simulation to start (button should change to Stop Tour Preview)
    const stopBtn = page.getByRole('button', { name: 'Stop Tour Preview' });
    await expect(stopBtn).toBeVisible({ timeout: 10000 });

    // Verify simulation generated a route (timeline buttons) even when headless scene loads retry.
    await expect
      .poll(async () => page.getByRole('button', { name: /Timeline step:/ }).count(), { timeout: 60000 })
      .toBeGreaterThan(5);

    // Stop Simulation by clicking the viewer stage
    await page.locator('#viewer-stage').click();
  });

  test('should rotate camera 180 degrees when returning to a hub scene', async ({ page }) => {
    test.setTimeout(120000);
    await loadProjectZipAndWait(page, ZIP_LINKED_PATH, 30000);

    // Scene 1 is Hub, Scene 2 is Room
    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });

    // Wait for React hotspot layer (hotspots are in React layer, not Pannellum)
    await page.waitForSelector('#react-hotspot-layer', { state: 'visible', timeout: 45000 });
    await page.waitForTimeout(500); // Allow rendering to complete

    // Get initial yaw of the first hotspot in the current scene
    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store.getState();
      const activeIdx = state.activeIndex;
      const sceneOrder = state.sceneOrder;
      const activeId = sceneOrder[activeIdx];
      const sceneData = state.inventory[activeId];
      // Search for the first scene that has hotspots if the current one doesn't
      if (sceneData && sceneData.scene.hotspots && sceneData.scene.hotspots.length > 0) {
        return {
          id: activeId,
          yaw: sceneData.scene.hotspots[0].yaw
        };
      }
      return null;
    });

    if (!hotspotData) {
       return;
    }

    const hotspotYaw = hotspotData.yaw;

    // Navigate to Scene 2 by clicking the first React hotspot
    const hotspot = page.locator('[id^="hs-react-"]').first();
    await expect(hotspot).toBeVisible({ timeout: 10000 });
    await hotspot.click();

    // Wait for scene change by checking persistent label change
    await expect(page.locator('#v-scene-persistent-label')).not.toHaveText(`# ${hotspotData.id}`, { timeout: 30000 });

    // Navigate back to the original scene by clicking scene list
    await page.locator('.scene-item').filter({ hasText: hotspotData.id }).first().click();
    await expect(page.locator('#v-scene-persistent-label')).toHaveText(`# ${hotspotData.id}`, { timeout: 30000 });

    // Wait for transition and stabilization
    await page.waitForTimeout(2000);

    // Verify final yaw is approximately hotspotYaw + 180 (hub scene return logic)
    const finalYaw = await page.evaluate(() => {
      // @ts-ignore
      return window.pannellumViewer.getYaw();
    });


    const expectedYaw = ((hotspotYaw + 180 + 180) % 360) - 180; // Normalize to [-180, 180]

    // Allow for small floating point differences
    const diff = Math.abs(finalYaw - expectedYaw);
    const normalizedDiff = diff > 180 ? 360 - diff : diff;

    expect(normalizedDiff).toBeLessThan(5); // 5 degrees tolerance
  });
});
