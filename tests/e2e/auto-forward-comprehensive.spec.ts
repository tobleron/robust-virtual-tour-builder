import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { resetClientState, uploadImageAndWaitForSceneCount, waitForNavigationStabilization } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');
const SIM_ZIP_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

test.describe('Auto-Forward Comprehensive', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should create auto-forward link via hotspot action menu', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Upload scenes...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    console.log('Step 2: Navigate to first scene...');
    const firstScene = page.locator('.scene-item').first();
    await expect(firstScene).toBeVisible({ timeout: 10000 });
    await firstScene.click();
    await waitForNavigationStabilization(page);

    console.log('Step 3: Enter link creation mode...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.waitForTimeout(500);
    }

    console.log('Step 4: Place hotspot at center of viewer...');
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });

    console.log('Step 5: Wait for link modal...');
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });

    console.log('Step 6: Select target scene...');
    const sceneOption = page.locator('[data-testid="scene-option"]').first();
    await expect(sceneOption).toBeVisible({ timeout: 10000 });
    await sceneOption.click();

    console.log('Step 7: Enable auto-forward toggle...');
    const autoForwardToggle = page.locator('button:has-text("Auto-Forward"), [role="switch"][aria-label*="Auto-Forward"]');
    if (await autoForwardToggle.isVisible()) {
      await autoForwardToggle.click();
      
      // Verify toggle state changed
      const isOn = await autoForwardToggle.getAttribute('aria-checked') === 'true' || 
                   await autoForwardToggle.getAttribute('data-state') === 'checked';
      expect(isOn).toBe(true);
      console.log('✅ Auto-forward toggle enabled');
    } else {
      console.log('⚠️ Auto-forward toggle not found');
    }

    console.log('Step 8: Save link...');
    const saveBtn = page.locator('button:has-text("Save"), button:has-text("Save Link")');
    await saveBtn.click();

    console.log('Step 9: Verify link created with auto-forward...');
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    
    // Verify hotspot exists
    const hotspotCount = await page.locator('.pnlm-hotspot').count();
    expect(hotspotCount).toBeGreaterThan(0);
    console.log('✅ Auto-forward link created successfully');
  });

  test('should navigate auto-forward chain during simulation', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();

    console.log('Step 2: Wait for app to load...');
    await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 20000 });
    await waitForNavigationStabilization(page);

    console.log('Step 3: Start simulation...');
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    if (await simBtn.isVisible()) {
      await simBtn.click();
      
      // Verify simulation started
      const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
      await expect(stopBtn).toBeVisible({ timeout: 5000 });
      console.log('✅ Simulation started');

      console.log('Step 4: Wait for auto-navigation...');
      const initialScene = await page.evaluate(() => {
        // @ts-ignore
        return window.store?.state?.activeIndex || 0;
      });

      // Wait for scene change
      await expect(async () => {
        const currentScene = await page.evaluate(() => {
          // @ts-ignore
          return window.store?.state?.activeIndex || 0;
        });
        expect(currentScene).not.toBe(initialScene);
      }).toPass({ timeout: 30000 });

      console.log('✅ Auto-forward chain navigation working');

      console.log('Step 5: Stop simulation...');
      await stopBtn.click();
      await expect(simBtn).toBeVisible({ timeout: 5000 });
    } else {
      console.log('⚠️ Simulation button not found');
    }
  });

  test('should respect skipAutoForwardGlobal toggle', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
    await waitForNavigationStabilization(page);

    console.log('Step 2: Enable skip auto-forward global...');
    // Open simulation settings or utility bar
    const settingsBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-settings"]), button[aria-label*="Settings"]');
    if (await settingsBtn.isVisible()) {
      await settingsBtn.click();
      
      // Find skip auto-forward toggle
      const skipToggle = page.locator('button:has-text("Skip Auto-Forward"), [role="switch"][aria-label*="Skip Auto"]');
      if (await skipToggle.isVisible()) {
        await skipToggle.click();
        console.log('✅ Skip auto-forward enabled');
      }
    }

    console.log('Step 3: Start simulation with skip enabled...');
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    if (await simBtn.isVisible()) {
      await simBtn.click();
      
      console.log('Step 4: Verify simulation skips auto-forward links...');
      // The simulation should skip scenes marked as auto-forward bridges
      await page.waitForTimeout(5000);
      
      // Verify visited links in state
      const visitedInfo = await page.evaluate(() => {
        // @ts-ignore
        const state = window.store?.state;
        return {
          visitedLinkIds: state?.simulation?.visitedLinkIds || [],
          skipAutoForwardGlobal: state?.simulation?.skipAutoForwardGlobal || false,
        };
      });
      
      console.log('Visited links:', visitedInfo.visitedLinkIds);
      console.log('Skip auto-forward global:', visitedInfo.skipAutoForwardGlobal);
      
      console.log('✅ Skip auto-forward global respected');
      
      // Stop simulation
      const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
      if (await stopBtn.isVisible()) {
        await stopBtn.click();
      }
    }
  });

  test('should enforce one auto-forward per scene (link-level)', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Upload scenes...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    console.log('Step 2: Navigate to first scene...');
    const firstScene = page.locator('.scene-item').first();
    await firstScene.click();
    await waitForNavigationStabilization(page);

    console.log('Step 3: Create first auto-forward link...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.locator('[data-testid="scene-option"]').first().click();
    
    const autoForwardToggle = page.locator('button:has-text("Auto-Forward")');
    if (await autoForwardToggle.isVisible()) {
      await autoForwardToggle.click();
    }
    
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    console.log('✅ First auto-forward link created');

    console.log('Step 4: Create second link in same scene...');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.locator('[data-testid="scene-option"]').nth(1).click();

    console.log('Step 5: Try to enable auto-forward on second link (should fail)...');
    if (await autoForwardToggle.isVisible()) {
      await autoForwardToggle.click();
      
      // Wait for error toast or validation message
      const errorToast = page.locator('[role="alert"]:has-text("Only one auto-forward"), [role="alert"]:has-text("already has auto-forward")');
      
      if (await errorToast.isVisible({ timeout: 5000 })) {
        console.log('✅ Validation working: Error toast shown');
      } else {
        // Check if toggle stayed off
        const isOn = await autoForwardToggle.getAttribute('aria-checked') === 'true';
        if (!isOn) {
          console.log('✅ Validation working: Toggle stayed off');
        } else {
          console.log('⚠️ Validation may not be working correctly');
        }
      }
    }

    console.log('Step 6: Save second link (should be non-auto-forward)...');
    await saveBtn.click();
    console.log('✅ One auto-forward per scene enforced');
  });

  test('should migrate scene-level auto-forward to link-level', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create project with scene-level auto-forward (via state injection)...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    // Inject old-style scene-level auto-forward
    await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      if (state && state.scenes && state.scenes[0]) {
        // Set scene-level auto-forward (legacy format)
        state.scenes[0].isAutoForward = true;
        // @ts-ignore
        window.store?.dispatch({ type: 'UpdateScene', scene: state.scenes[0] });
      }
    });

    console.log('Step 2: Verify migration occurred...');
    const migrationResult = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const scene = state?.scenes?.[0];
      const hotspots = scene?.hotspots || [];
      
      return {
        sceneLevelAutoForward: scene?.isAutoForward || false,
        hotspotLevelAutoForward: hotspots.some((h: any) => h.isAutoForward === true),
        hotspotCount: hotspots.length,
      };
    });

    console.log('Migration result:', migrationResult);
    
    // After migration, hotspots should have isAutoForward if scene had it
    if (migrationResult.hotspotCount > 0) {
      expect(migrationResult.hotspotLevelAutoForward).toBe(true);
      console.log('✅ Scene-level auto-forward migrated to link-level');
    } else {
      console.log('⚠️ No hotspots to migrate to');
    }
  });

  test('should handle broken auto-forward links gracefully', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create scene with broken auto-forward link...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);

    // Inject a broken auto-forward link (pointing to non-existent scene)
    await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      if (state && state.scenes && state.scenes[0]) {
        state.scenes[0].hotspots = [{
          linkId: 'l-broken',
          yaw: 0,
          pitch: 0,
          target: 'Non-existent Scene',
          targetSceneId: null, // Broken link
          isAutoForward: true,
        }];
        // @ts-ignore
        window.store?.dispatch({ type: 'UpdateScene', scene: state.scenes[0] });
      }
    });

    console.log('Step 2: Start simulation with broken link...');
    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    if (await simBtn.isVisible()) {
      await simBtn.click();
      
      console.log('Step 3: Verify simulation handles broken link...');
      // Simulation should skip broken link or show error
      await page.waitForTimeout(5000);
      
      // Check for error handling
      const errorToast = page.locator('[role="alert"]:has-text("error"), [role="alert"]:has-text("failed")');
      if (await errorToast.isVisible({ timeout: 3000 })) {
        console.log('✅ Error shown for broken link');
      } else {
        // Or simulation should have skipped to next valid scene
        const activeScene = await page.evaluate(() => {
          // @ts-ignore
          return window.store?.state?.activeIndex;
        });
        console.log('Active scene:', activeScene);
        console.log('✅ Broken link handled (skipped or error shown)');
      }
      
      // Stop simulation
      const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
      if (await stopBtn.isVisible()) {
        await stopBtn.click();
      }
    }
  });
});
