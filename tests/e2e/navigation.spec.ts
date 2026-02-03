import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const ZIP_LINKED_PATH = path.join(FIXTURES_DIR, 'tour_linked.vt.zip');
const ZIP_SIM_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

test.describe('Navigation Engine', () => {
  test('should navigate between scenes via hotspot', async ({ page }) => {
    test.setTimeout(60000);
    await page.goto('/');
    const fileInput = page.locator('input[type="file"][accept=".vt.zip,.zip"]');
    await fileInput.setInputFiles(ZIP_LINKED_PATH);

    try {
        const startBtn = page.getByRole('button', { name: 'Start Building' });
        await startBtn.waitFor({ state: 'visible', timeout: 5000 });
        await startBtn.click();
    } catch (e) { }

    await expect(page.getByText('Scene 1', { exact: true })).toBeVisible();

    // Wait for viewer ready
    await page.waitForSelector('#panorama-a.active', { state: 'visible' });

    // Try to find hotspot
    try {
      await page.waitForSelector('.pnlm-hotspot', { state: 'attached', timeout: 10000 });
      await page.locator('.pnlm-hotspot').first().click();
    } catch (e) {
      console.log('Hotspot element not found, trying center click fallback');
      const viewer = page.locator('#viewer-stage');
      const box = await viewer.boundingBox();
      if (box) {
        await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      }
    }

    // Expect Hotspot Action Menu and click GO
    const goBtn = page.getByRole('button', { name: 'GO' });
    await expect(goBtn).toBeVisible({ timeout: 10000 });
    await goBtn.click();

    // Verify Scene 2 becomes active via persistent label
    await expect(page.locator('#v-scene-persistent-label')).toHaveText('# Scene 2', { timeout: 20000 });
  });

  test('should run simulation mode and auto-navigate', async ({ page }) => {
    test.setTimeout(60000);
    await page.goto('/');
    const fileInput = page.locator('input[type="file"][accept=".vt.zip,.zip"]');
    await fileInput.setInputFiles(ZIP_SIM_PATH);

    try {
        const startBtn = page.getByRole('button', { name: 'Start Building' });
        await startBtn.waitFor({ state: 'visible', timeout: 5000 });
        await startBtn.click();
    } catch (e) { }

    await expect(page.getByText('Scene 1', { exact: true })).toBeVisible();
    await expect(page.locator('#v-scene-persistent-label')).toHaveText('# Scene 1');

    const teaserBtn = page.getByRole('button', { name: 'Teaser' });
    await expect(teaserBtn).toBeEnabled();
    await teaserBtn.click();

    // Wait for auto-navigation.
    await expect(page.locator('#v-scene-persistent-label')).toHaveText('# Scene 2', { timeout: 30000 });

    // Stop Simulation
    await page.locator('#viewer-stage').click();
  });
});
