import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability, setupAuthentication } from './ai-helper';
import { loadProjectZipAndWait } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const SIM_ZIP_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

test.describe('Simulation & Teaser', () => {
  test.beforeEach(async ({ page }) => {
    await setupAuthentication(page, 'dev-token');
    await setupAIObservability(page);
    await page.goto('/builder');

    // Clear state
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 60000);
  });

  test('should run autopilot simulation', async ({ page }) => {
    test.setTimeout(120000);

    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    await expect(simBtn).toBeVisible();
    await simBtn.click();

    // Verify simulation is running (button should change to Square)
    const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
    await expect(stopBtn).toBeVisible();

    // Wait for at least one transition
    // Wait for at least one scene to be active
    await expect(page.locator('.scene-item.active')).toBeVisible({ timeout: 15000 });

    const initialActiveIndex = await page.evaluate(() => (window as any).__RE_STATE__?.activeIndex ?? -1);
    expect(initialActiveIndex).not.toBe(-1);

    await expect(async () => {
      const state = await page.evaluate(() => (window as any).__RE_STATE__);
      expect(state?.activeIndex).not.toBe(initialActiveIndex);
      expect(state?.activeIndex).not.toBe(-1);
    }).toPass({ timeout: 120000 });

    await stopBtn.click();
    await expect(simBtn).toBeVisible();
  });

  test('should run auto teaser and download', async ({ page }) => {
    test.setTimeout(300000);

    const teaserBtn = page.getByLabel('Create Teaser');
    await expect(teaserBtn).toBeVisible();
    await teaserBtn.click();

    // Verify it's running via overlay existence
    const overlay = page.locator('#teaser-overlay');
    await expect(overlay).toBeAttached({ timeout: 10000 });

    const downloadPromise = page.waitForEvent('download', { timeout: 240000 });

    const download = await downloadPromise;
    const filename = download.suggestedFilename();
    expect(filename).toMatch(/\.(webm|mp4)$/);
    expect(await download.failure()).toBeNull();
  });

  test('should enforce one auto-forward link per scene', async ({ page }) => {
    test.setTimeout(60000);

    
    // Create first link
    const linkModeBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await expect(linkModeBtn).toBeVisible();
    await linkModeBtn.click();
    
    // Place first hotspot
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    // Wait for link modal
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });
    
    // Select a target scene
    await page.selectOption('#link-target', { index: 1 });
    
    // Enable auto-forward on first link
    const autoForwardToggle = page.locator('button:has-text("Auto-Forward")');
    await expect(autoForwardToggle).toBeVisible();
    await autoForwardToggle.click();
    
    // Save first link
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    
    
    // Create second link
    await linkModeBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });
    
    // Wait for link modal
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });
    await page.selectOption('#link-target', { index: 2 });
    
    
    // Try to enable auto-forward on second link - should show error
    await autoForwardToggle.click();
    
    // Wait for error toast
    const errorToast = page.locator('[role="alert"]:has-text("Only one auto-forward")');
    await expect(errorToast).toBeVisible({ timeout: 5000 });
    
    
    // The auto-forward toggle should still be in off state (or modal closed with error)
    // Save the second link (it should be non-auto-forward)
    await saveBtn.click();
    
  });
});
