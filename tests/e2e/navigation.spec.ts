import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const ZIP_LINKED_PATH = path.join(FIXTURES_DIR, 'tour_linked.vt.zip');
const ZIP_SIM_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

test.describe('Navigation Engine', () => {
  test.beforeEach(async ({ page }) => {
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
    test.setTimeout(60000);
    const fileInput = page.locator('input[type="file"][accept=".vt.zip,.zip"]');
    await fileInput.setInputFiles(ZIP_LINKED_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await startBtn.waitFor({ state: 'visible', timeout: 30000 });
    await startBtn.click();

    await expect(page.locator('.scene-item').filter({ hasText: 'Scene 1' }).first()).toBeVisible({ timeout: 20000 });

    // Wait for viewer ready
    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });

    // Try to find hotspot - wait longer
    await page.waitForSelector('.pnlm-hotspot', { state: 'attached', timeout: 45000 });

    // Sometimes the click on pnlm-hotspot fails if it's not actually interactive in the way Playwright expects
    // Click center of viewer as fallback if it doesn't navigate
    await page.locator('.pnlm-hotspot').first().click();

    // Expect Hotspot Action Menu and click GO
    const goBtn = page.getByRole('button', { name: 'GO' });
    await expect(goBtn).toBeVisible({ timeout: 15000 });
    await goBtn.click();

    // Verify Scene 2 becomes active via persistent label. The label is prefixed with '# '
    await expect(page.locator('#v-scene-persistent-label')).toHaveText('# Scene 2', { timeout: 30000 });
  });

  test('should run simulation mode and auto-navigate', async ({ page }) => {
    test.setTimeout(90000);
    const fileInput = page.locator('input[type="file"][accept=".vt.zip,.zip"]');
    await fileInput.setInputFiles(ZIP_SIM_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await startBtn.waitFor({ state: 'visible', timeout: 30000 });
    await startBtn.click();

    await expect(page.locator('.scene-item').filter({ hasText: 'Scene 1' }).first()).toBeVisible({ timeout: 20000 });
    await expect(page.locator('#v-scene-persistent-label')).toHaveText('# Scene 1', { timeout: 10000 });

    const teaserBtn = page.getByRole('button', { name: 'Teaser' });
    await expect(teaserBtn).toBeEnabled({ timeout: 10000 });
    await teaserBtn.click();

    // Wait for auto-navigation.
    await expect(page.locator('#v-scene-persistent-label')).toHaveText('# Scene 2', { timeout: 45000 });

    // Stop Simulation
    await page.locator('#viewer-stage').click();
  });
});
