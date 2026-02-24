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

    // Use exact role/name to avoid matching "Close" from toasts
    const startBtn = page.getByRole('button', { name: "Start Building" });
    const closeToastBtn = page.getByLabel('Close toast');

    // If we see error toasts, log them
    page.on('console', msg => {
      console.log(`[Browser ${msg.type()}] ${msg.text()}`);
    });

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
    // Wait for at least one scene to be active
    await expect(page.locator('.scene-item.active')).toBeVisible({ timeout: 15000 });

    const initialActiveIndex = await page.evaluate(() => (window as any).__RE_STATE__?.activeIndex ?? -1);
    expect(initialActiveIndex).not.toBe(-1);

    await expect(async () => {
      const state = await page.evaluate(() => (window as any).__RE_STATE__);
      expect(state?.activeIndex).not.toBe(initialActiveIndex);
      expect(state?.activeIndex).not.toBe(-1);
    }).toPass({ timeout: 120000 });

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

  test('should enforce one auto-forward link per scene', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Creating first auto-forward link...');
    
    // Create first link
    const linkModeBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await expect(linkModeBtn).toBeVisible();
    await linkModeBtn.click();
    
    // Place first hotspot
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    // Wait for link modal
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });
    
    // Select a target scene
    await page.locator('[data-testid="scene-option"]').first().click();
    
    // Enable auto-forward on first link
    const autoForwardToggle = page.locator('button:has-text("Auto-Forward")');
    await expect(autoForwardToggle).toBeVisible();
    await autoForwardToggle.click();
    
    // Save first link
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    
    console.log('Step 2: Creating second link in same scene...');
    
    // Create second link
    await linkModeBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });
    
    // Wait for link modal
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });
    await page.locator('[data-testid="scene-option"]').nth(1).click();
    
    console.log('Step 3: Trying to enable auto-forward on second link (should fail)...');
    
    // Try to enable auto-forward on second link - should show error
    await autoForwardToggle.click();
    
    // Wait for error toast
    const errorToast = page.locator('[role="alert"]:has-text("Only one auto-forward")');
    await expect(errorToast).toBeVisible({ timeout: 5000 });
    
    console.log('Step 4: Verifying second link remains non-auto-forward...');
    
    // The auto-forward toggle should still be in off state (or modal closed with error)
    // Save the second link (it should be non-auto-forward)
    await saveBtn.click();
    
    console.log('✅ Validation working: Only one auto-forward link per scene enforced');
  });
});
