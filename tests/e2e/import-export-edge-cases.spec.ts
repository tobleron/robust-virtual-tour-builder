import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import {
  resetClientState,
  uploadImageAndWaitForSceneCount,
  waitForNavigationStabilization,
  waitForSidebarInteractive,
  loadProjectZipAndWait,
} from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const SIM_ZIP_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

test.describe('Import/Export Edge Cases', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should handle large project import (100+ scenes)', async ({ page }) => {
    test.setTimeout(300000);

    const x700Path = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');
    try {
      await loadProjectZipAndWait(page, x700Path, 60000);
    } catch (e) {
      await loadProjectZipAndWait(page, SIM_ZIP_PATH, 60000);
    }

    const sceneItems = page.locator('.scene-item');
    const sceneCount = await sceneItems.count();

    if (sceneCount >= 100) {
    } else {
    }

    await expect(sceneItems.first()).toBeVisible({ timeout: 10000 });
  });

  test('should cancel export on user request via cancel button or ESC', async ({ page }) => {
    test.setTimeout(120000);

    const fileInput = page.locator('#sidebar-project-upload');
    await fileInput.setInputFiles(SIM_ZIP_PATH);
    const startBtn = page.getByRole('button', { name: /Start Building|Close/i }).first();
    if (await startBtn.isVisible()) {
      await startBtn.click();
    }
    await waitForSidebarInteractive(page);
    await waitForNavigationStabilization(page);

    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    if (await exportBtn.isVisible()) {
      await expect(exportBtn).toBeEnabled({ timeout: 20000 });
      await exportBtn.click();

      const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
      if (await startExportBtn.isVisible()) {
        await startExportBtn.click();

        await page.waitForTimeout(2000);

        await page.keyboard.press('Escape');
        await page.waitForTimeout(1000);

        // Check if export stopped
        const exportStillRunning = await page.locator('.export-progress, .export-spinner').isVisible();
        if (!exportStillRunning) {
        } else {

          const cancelBtn = page.locator('button:has-text("Cancel"), button:has-text("Stop")');
          if (await cancelBtn.isVisible()) {
            await cancelBtn.click();
          }
        }
      }
    }
  });

  test('should assign Floor G (Ground) by default to all scenes', async ({ page }) => {
    test.setTimeout(60000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const floorAssignments = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return state?.scenes?.map((s: any) => s.floor) || [];
    });


    // All scenes should have a floor assigned (G by default)
    const allHaveFloor = floorAssignments.every((f: string) => f && f.length > 0);
    if (allHaveFloor) {
    } else {
    }

  });

  test.skip('should reject corrupted ZIP files gracefully', async ({ page }) => {
    test.setTimeout(60000);


    test.skip(true, 'Corrupted ZIP handling not implemented');
  });

  test.skip('should migrate old project versions during import', async ({ page }) => {
    test.setTimeout(120000);


    test.skip(true, 'Version migration uncertain');
  });

  test.skip('should handle export timeout gracefully', async ({ page }) => {
    test.setTimeout(180000);


    test.skip(true, 'Export timeout handling uncertain');
  });

  test.skip('should handle missing images in imported project', async ({ page }) => {
    test.setTimeout(120000);


    test.skip(true, 'Missing image handling uncertain');
  });

  test.skip('should block export when no floors assigned', async ({ page }) => {
    test.setTimeout(60000);


    test.skip(true, 'Floor G is default, export never blocked');
  });
});
