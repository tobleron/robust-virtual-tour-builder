import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const SIM_ZIP_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

test.describe('Simulation & Teaser', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await page.goto('/');
    
    // Clear state
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();

    // Import the simulation tour
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);
    const startBtn = page.getByRole('button', { name: /Start Building|Close/i });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
  });

  test('should run autopilot simulation', async ({ page }) => {
    test.setTimeout(120000);
    
    console.log('Step 1: Starting simulation...');
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    await expect(simBtn).toBeVisible();
    await simBtn.click();

    // Verify simulation is running (button should change to Square)
    const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
    await expect(stopBtn).toBeVisible();

    // Wait for at least one transition
    console.log('Step 2: Waiting for scene transition...');
    const initialActiveIndex = await page.evaluate(() => {
        const items = Array.from(document.querySelectorAll('.scene-item'));
        return items.findIndex(el => el.classList.contains('active'));
    });

    await expect(async () => {
         const currentActiveIndex = await page.evaluate(() => {
            const items = Array.from(document.querySelectorAll('.scene-item'));
            return items.findIndex(el => el.classList.contains('active'));
        });
        expect(currentActiveIndex).not.toBe(initialActiveIndex);
        expect(currentActiveIndex).not.toBe(-1);
    }).toPass({ timeout: 60000 });

    console.log('Step 3: Stopping simulation...');
    await stopBtn.click();
    await expect(simBtn).toBeVisible();
  });

  test('should run auto teaser and download', async ({ page }) => {
    test.setTimeout(300000);

    console.log('Step 1: Starting auto teaser...');
    const teaserBtn = page.getByLabel('Create Teaser');
    await expect(teaserBtn).toBeVisible();
    await teaserBtn.click();

    // Verify it's running via overlay existence
    const overlay = page.locator('#teaser-overlay');
    await expect(overlay).toBeAttached({ timeout: 10000 });

    console.log('Step 2: Waiting for teaser to complete and download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 240000 });
    
    const download = await downloadPromise;
    const filename = download.suggestedFilename();
    console.log('Downloaded filename:', filename);
    expect(filename).toMatch(/\.(webm|mp4)$/);
    expect(await download.failure()).toBeNull();
  });
});
