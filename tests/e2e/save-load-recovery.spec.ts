import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { setupAIObservability, setupAuthentication } from './ai-helper';
import { clickStartBuildingIfVisible, waitForSidebarInteractive } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

async function handleUpload(page, imagePath, expectedSceneIndex) {
  const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
  await fileInput.setInputFiles([imagePath]);

  try {
    await clickStartBuildingIfVisible(page, 90000);
    await waitForSidebarInteractive(page, 90000);
  } catch (e) {
  }

  await expect(page.locator('.scene-item').nth(expectedSceneIndex)).toBeVisible({ timeout: 90000 });
}

test.describe('Project Persistence: Save -> Load Recovery', () => {
  test.beforeEach(async ({ page }) => {
    await setupAuthentication(page, 'dev-token');
    await setupAIObservability(page);
    await page.goto('/builder');
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();
    await page.waitForLoadState('networkidle');
  });

  test('should persist project data through save/load cycle', async ({ page }) => {
    test.setTimeout(300000);

    // 1. Create Project with 2 scenes
    await handleUpload(page, IMAGE_PATH_1, 0);
    await handleUpload(page, IMAGE_PATH_2, 1);

    // Add a hotspot to Scene 1
    await page.locator('.scene-item').nth(0).click();
    await page.waitForTimeout(2000); // Wait for viewer stabilization
    const viewer = page.locator('#viewer-stage');
    const box = await viewer.boundingBox();

    await page.keyboard.down('Alt');
    if (box) await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await page.keyboard.up('Alt');

    await expect(page.getByText('Link Destination')).toBeVisible();
    await page.selectOption('#link-target', { index: 1 });
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden();

    // 2. Save Project (Download)
    const saveBtn = page.getByLabel('Save');
    await expect(saveBtn).toBeVisible();

    const downloadPromise = page.waitForEvent('download');
    await saveBtn.click();
    const download = await downloadPromise;
    const savePath = path.join(__dirname, 'temp_saved_project.zip');
    await download.saveAs(savePath);

    // 3. Clear State & Reload (Simulate Reset)
    const newBtn = page.getByLabel('New');
    if (await newBtn.isVisible()) {
      await newBtn.click();
      // Expect a dialog asking to save or reset, if implemented
      // For now, assume it might just reset or show a prompt. 
      // If a native confirm dialog appears, playwright handles it if configured, 
      // otherwise we reload the page to be sure.
      await page.reload();
    } else {
      await page.reload();
    }

    // Hard clear to be safe
    await page.evaluate(async () => {
      localStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();

    // Verify empty state
    const sceneCount = await page.locator('.scene-item').count();
    expect(sceneCount).toBe(0);

    // 4. Load Project (Upload Zip)
    // The load button now likely accepts .zip only as per user spec
    const loadInput = page.locator('input[type="file"][accept*=".zip"]');

    if (await loadInput.count() > 0) {
      await loadInput.setInputFiles(savePath);
    } else {
      // Fallback if input is hidden behind button
      const loadBtn = page.getByLabel('Load');
      const fileChooserPromise = page.waitForEvent('filechooser');
      await loadBtn.click();
      const fileChooser = await fileChooserPromise;
      await fileChooser.setFiles(savePath);
    }

    // 5. Verify Restoration
    await expect(page.locator('.scene-item').nth(0)).toBeVisible({ timeout: 30000 });
    await expect(page.locator('.scene-item').nth(1)).toBeVisible();

    // Verify hotspot existence via state check
    const state = await page.evaluate(() => {
      // @ts-ignore
      return window.store ? window.store.getState() : null;
    });

    if (state && state.inventory && state.sceneOrder) {
      const scenes = state.sceneOrder
        .map((id: string) => state.inventory.get(id))
        .filter(Boolean)
        .map((entry: any) => entry.scene)
        .filter(scene => scene);

      const hasHotspots = scenes.some(
        (s: any) => Array.isArray(s.hotspots) && s.hotspots.length > 0,
      );
      if (!hasHotspots) console.warn('No hotspots found in state dump');
      expect(hasHotspots).toBeTruthy();
    } else {
      console.warn("Could not access window.store for verification");
    }

    // Cleanup
    if (fs.existsSync(savePath)) {
      fs.unlinkSync(savePath);
    }
  });
});
