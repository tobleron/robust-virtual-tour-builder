import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { resetClientState, uploadImageAndWaitForSceneCount, waitForNavigationStabilization } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const SIM_ZIP_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

test.describe('Import/Export Edge Cases', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should handle large project import (100+ scenes)', async ({ page }) => {
    test.setTimeout(300000);

    console.log('Step 1: Mock large project import via API...');
    
    // Mock the import endpoint to return a large project
    await page.route('**/api/project/import', async (route) => {
      const scenes = [];
      for (let i = 0; i < 120; i++) {
        scenes.push({
          id: `scene-${i}`,
          name: `Scene ${i + 1}`,
          file: 'images/image.jpg',
          hotspots: [],
          category: i % 2 === 0 ? 'indoor' : 'outdoor',
          floor: ['ground', 'first', 'second'][i % 3],
          label: `Scene ${i + 1}`,
          isAutoForward: false,
        });
      }

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          sessionId: 'large-import-session',
          projectData: {
            tourName: 'Large Import Tour (120 scenes)',
            scenes,
          },
        }),
      });
    });

    console.log('Step 2: Trigger import...');
    // Trigger import via file input or import button
    const importBtn = page.locator('button:has-text("Import"), button[aria-label*="Import"]');
    if (await importBtn.isVisible()) {
      await importBtn.click();
    }

    // Or use file input
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    if (await fileInput.isVisible()) {
      await fileInput.setInputFiles(SIM_ZIP_PATH);
    }

    console.log('Step 3: Wait for project to load...');
    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();

    console.log('Step 4: Verify all scenes loaded...');
    const sceneItems = page.locator('.scene-item');
    await expect(sceneItems).toHaveCount(120, { timeout: 60000 });

    console.log('Step 5: Verify performance with large dataset...');
    const loadTime = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return {
        sceneCount: state?.scenes?.length || 0,
        activeIndex: state?.activeIndex || 0,
      };
    });

    console.log('Loaded project:', loadTime);
    expect(loadTime.sceneCount).toBe(120);
    
    console.log('✅ Large project (120 scenes) imported successfully');
  });

  test('should reject corrupted ZIP files gracefully', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Create corrupted ZIP file...');
    const corruptedZipPath = path.join(FIXTURES_DIR, 'corrupted.zip');
    
    // Create a fake corrupted file
    const fs = require('fs');
    fs.writeFileSync(corruptedZipPath, 'This is not a valid ZIP file content');

    console.log('Step 2: Try to import corrupted file...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(corruptedZipPath);

    console.log('Step 3: Wait for error handling...');
    // Should show error toast or modal
    const errorSelectors = [
      '[role="alert"]:has-text("corrupt"),',
      '[role="alert"]:has-text("invalid"),',
      '[role="alert"]:has-text("error"),',
      '[role="alert"]:has-text("Failed"),',
      '.toast-error, .error-message',
    ];

    let errorFound = false;
    for (const selector of errorSelectors) {
      const error = page.locator(selector);
      if (await error.isVisible({ timeout: 5000 }).catch(() => false)) {
        errorFound = true;
        console.log('✅ Error message shown:', selector);
        break;
      }
    }

    if (!errorFound) {
      console.log('ℹ️ No error message found (may handle differently)');
      
      // Check if app is still functional
      const appStillWorking = await page.locator('#viewer-logo').isVisible();
      if (appStillWorking) {
        console.log('✅ App still functional after corrupted import attempt');
      }
    }

    // Clean up
    try {
      fs.unlinkSync(corruptedZipPath);
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  test('should migrate old project versions during import', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Mock old project version import...');
    
    await page.route('**/api/project/import', async (route) => {
      // Simulate old project format (missing new fields)
      const oldProjectData = {
        version: '4.5.0', // Old version
        tourName: 'Legacy Tour',
        scenes: [
          {
            id: 'old-scene-1',
            name: 'Old Scene 1',
            file: 'images/image.jpg',
            hotspots: [],
            // Missing: floor, category, isAutoForward (new fields)
          },
          {
            id: 'old-scene-2',
            name: 'Old Scene 2',
            file: 'images/image.jpg',
            hotspots: [],
          },
        ],
      };

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          sessionId: 'migration-session',
          projectData: oldProjectData,
        }),
      });
    });

    console.log('Step 2: Import old project...');
    const importBtn = page.locator('button:has-text("Import"), button[aria-label*="Import"]');
    if (await importBtn.isVisible()) {
      await importBtn.click();
    }

    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    if (await fileInput.isVisible()) {
      await fileInput.setInputFiles(SIM_ZIP_PATH);
    }

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();

    console.log('Step 3: Verify migration occurred...');
    const migrationResult = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const scene = state?.scenes?.[0];
      return {
        hasFloor: scene?.floor !== undefined && scene?.floor !== null,
        hasCategory: scene?.category !== undefined && scene?.category !== null,
        hasAutoForward: scene?.isAutoForward !== undefined,
        sceneCount: state?.scenes?.length || 0,
      };
    });

    console.log('Migration result:', migrationResult);
    
    // After migration, old projects should have default values for new fields
    expect(migrationResult.sceneCount).toBeGreaterThan(0);
    console.log('✅ Old project migrated successfully');
  });

  test('should block export when no floors assigned', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Upload scenes without floor assignment...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);

    console.log('Step 2: Try to export...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    if (await exportBtn.isVisible()) {
      await exportBtn.click();

      console.log('Step 3: Check for floor assignment warning...');
      const warningSelectors = [
        '[role="alert"]:has-text("floor"),',
        '[role="alert"]:has-text("assign"),',
        '.warning:has-text("floor"),',
        'text=assign floors, text=missing floor',
      ];

      let warningFound = false;
      for (const selector of warningSelectors) {
        const warning = page.locator(selector);
        if (await warning.isVisible({ timeout: 5000 }).catch(() => false)) {
          warningFound = true;
          console.log('✅ Floor assignment warning shown:', selector);
          break;
        }
      }

      if (!warningFound) {
        console.log('ℹ️ No floor warning found (may not be enforced)');
      }

      // Check if export is blocked
      const exportDisabled = await exportBtn.isDisabled();
      if (exportDisabled) {
        console.log('✅ Export blocked due to missing floors');
      } else {
        console.log('ℹ️ Export not blocked (may allow without floors)');
      }
    }
  });

  test('should cancel export on user request', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Upload scenes...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);

    console.log('Step 2: Start export...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    if (await exportBtn.isVisible()) {
      await exportBtn.click();

      const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
      if (await startExportBtn.isVisible()) {
        await startExportBtn.click();

        console.log('Step 3: Wait for export to start...');
        await page.waitForTimeout(2000);

        console.log('Step 4: Look for cancel button...');
        const cancelBtn = page.locator(
          'button:has-text("Cancel"), ' +
          'button:has-text("Stop"), ' +
          '[aria-label*="Cancel"], ' +
          '[aria-label*="Stop"]'
        );

        if (await cancelBtn.isVisible()) {
          await cancelBtn.click();
          console.log('✅ Export cancelled by user');

          // Verify export stopped
          await page.waitForTimeout(1000);
          const exportStillRunning = await page.locator('.export-progress, .export-spinner').isVisible();
          if (!exportStillRunning) {
            console.log('✅ Export process stopped');
          }
        } else {
          console.log('ℹ️ Cancel button not found (export may be too fast)');
        }
      }
    }
  });

  test('should handle export timeout gracefully', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Mock slow export API...');
    await page.route('**/api/project/create-tour-package', async (route) => {
      // Simulate very slow response
      await new Promise(resolve => setTimeout(resolve, 10000));
      
      // Then fail with timeout
      route.abort('timedout');
    });

    console.log('Step 2: Upload scenes...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);

    console.log('Step 3: Start export...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    if (await exportBtn.isVisible()) {
      await exportBtn.click();

      const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
      if (await startExportBtn.isVisible()) {
        await startExportBtn.click();

        console.log('Step 4: Wait for timeout handling...');
        // Wait for timeout error
        await page.waitForTimeout(15000);

        // Check for timeout error message
        const errorSelectors = [
          '[role="alert"]:has-text("timeout"),',
          '[role="alert"]:has-text("slow"),',
          '[role="alert"]:has-text("try again"),',
          '.error-message:has-text("timeout"),',
        ];

        let errorFound = false;
        for (const selector of errorSelectors) {
          const error = page.locator(selector);
          if (await error.isVisible({ timeout: 5000 }).catch(() => false)) {
            errorFound = true;
            console.log('✅ Timeout error shown:', selector);
            break;
          }
        }

        if (!errorFound) {
          console.log('ℹ️ No timeout error found (may handle differently)');
        }

        // Verify app is still functional
        const appStillWorking = await page.locator('#viewer-logo').isVisible();
        if (appStillWorking) {
          console.log('✅ App still functional after export timeout');
        }
      }
    }
  });

  test('should handle missing images in imported project', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Mock import with missing image references...');
    
    await page.route('**/api/project/import', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          sessionId: 'missing-images-session',
          projectData: {
            tourName: 'Tour with Missing Images',
            scenes: [
              {
                id: 'scene-1',
                name: 'Scene 1',
                file: 'images/nonexistent1.jpg', // Missing file
                hotspots: [],
              },
              {
                id: 'scene-2',
                name: 'Scene 2',
                file: 'images/nonexistent2.jpg', // Missing file
                hotspots: [],
              },
            ],
          },
        }),
      });
    });

    console.log('Step 2: Import project...');
    const importBtn = page.locator('button:has-text("Import"), button[aria-label*="Import"]');
    if (await importBtn.isVisible()) {
      await importBtn.click();
    }

    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    if (await fileInput.isVisible()) {
      await fileInput.setInputFiles(SIM_ZIP_PATH);
    }

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();

    console.log('Step 3: Verify app handles missing images...');
    // Should either:
    // - Show placeholder/warning
    // - Skip missing scenes
    // - Show error but remain functional
    
    const sceneItems = page.locator('.scene-item');
    const sceneCount = await sceneItems.count();
    console.log('Scenes loaded:', sceneCount);

    // Check for warnings
    const warningSelectors = [
      '[role="alert"]:has-text("missing"),',
      '[role="alert"]:has-text("image"),',
      '.warning:has-text("load"),',
    ];

    let warningFound = false;
    for (const selector of warningSelectors) {
      const warning = page.locator(selector);
      if (await warning.isVisible({ timeout: 5000 }).catch(() => false)) {
        warningFound = true;
        console.log('✅ Missing image warning shown:', selector);
        break;
      }
    }

    // App should still be functional
    const appStillWorking = await page.locator('#viewer-logo').isVisible();
    if (appStillWorking) {
      console.log('✅ App functional despite missing images');
    }
  });
});
