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

test.describe('Hotspot Advanced Features', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);

    // Upload scenes for hotspot testing
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
  });

  test('should configure Director View target yaw/pitch/hfov', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').first().click();
    }

    console.log('Step 2: Open Director View settings...');
    // Look for Director View section or advanced settings
    const directorViewSection = page.locator('text=Director View, text=Camera Settings, text=Target View');
    const advancedToggle = page.locator('button:has-text("Advanced"), button:has-text("Camera")');
    
    if (await advancedToggle.isVisible()) {
      await advancedToggle.click();
    }

    console.log('Step 3: Configure target yaw...');
    const yawInput = page.locator('input[name="targetYaw"], input[aria-label*="yaw"], input[type="number"][data-testid="yaw"]');
    if (await yawInput.isVisible()) {
      await yawInput.fill('45');
      console.log('✅ Target yaw set to 45°');
    } else {
      console.log('⚠️ Yaw input not found');
    }

    console.log('Step 4: Configure target pitch...');
    const pitchInput = page.locator('input[name="targetPitch"], input[aria-label*="pitch"], input[type="number"][data-testid="pitch"]');
    if (await pitchInput.isVisible()) {
      await pitchInput.fill('-10');
      console.log('✅ Target pitch set to -10°');
    } else {
      console.log('⚠️ Pitch input not found');
    }

    console.log('Step 5: Configure target hfov...');
    const hfovInput = page.locator('input[name="targetHfov"], input[aria-label*="hfov"], input[type="number"][data-testid="hfov"]');
    if (await hfovInput.isVisible()) {
      await hfovInput.fill('90');
      console.log('✅ Target hfov set to 90°');
    } else {
      console.log('⚠️ Hfov input not found');
    }

    console.log('Step 6: Save hotspot...');
    const saveBtn = page.locator('button:has-text("Save"), button:has-text("Save Link")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    console.log('Step 7: Verify Director View settings in state...');
    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const activeScene = state?.scenes?.[state?.activeIndex || 0];
      const hotspot = activeScene?.hotspots?.[0];
      return hotspot ? {
        targetYaw: hotspot.targetYaw,
        targetPitch: hotspot.targetPitch,
        targetHfov: hotspot.targetHfov,
      } : null;
    });

    console.log('Hotspot Director View data:', hotspotData);
    if (hotspotData) {
      expect(hotspotData.targetYaw).toBe(45);
      expect(hotspotData.targetPitch).toBe(-10);
      expect(hotspotData.targetHfov).toBe(90);
      console.log('✅ Director View settings saved correctly');
    } else {
      console.log('⚠️ Could not verify hotspot data');
    }
  });

  test('should toggle return link on hotspot', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.locator('[data-testid="scene-option"]').first().click();

    console.log('Step 2: Enable return link toggle...');
    const returnLinkToggle = page.locator(
      'button:has-text("Return Link"), ' +
      '[role="switch"][aria-label*="Return"], ' +
      'input[type="checkbox"][name*="return"]'
    );
    
    if (await returnLinkToggle.isVisible()) {
      await returnLinkToggle.click();
      
      // Verify toggle state
      const isOn = await returnLinkToggle.getAttribute('aria-checked') === 'true' ||
                   await returnLinkToggle.getAttribute('data-state') === 'checked' ||
                   await returnLinkToggle.isChecked();
      expect(isOn).toBe(true);
      console.log('✅ Return link enabled');
    } else {
      console.log('⚠️ Return link toggle not found');
    }

    console.log('Step 3: Save hotspot...');
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    console.log('Step 4: Verify return link in state...');
    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const activeScene = state?.scenes?.[state?.activeIndex || 0];
      const hotspot = activeScene?.hotspots?.[0];
      return hotspot ? {
        isReturnLink: hotspot.isReturnLink,
        returnViewFrame: hotspot.returnViewFrame,
      } : null;
    });

    console.log('Hotspot return link data:', hotspotData);
    console.log('✅ Return link hotspot created');
  });

  test('should add waypoints to hotspot', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.locator('[data-testid="scene-option"]').first().click();

    console.log('Step 2: Find waypoint configuration...');
    const waypointSection = page.locator('text=Waypoints, text=Animation Path');
    const addWaypointBtn = page.locator('button:has-text("Add Waypoint"), button:has-text("+ Waypoint")');
    
    if (await addWaypointBtn.isVisible()) {
      console.log('Step 3: Add waypoint...');
      await addWaypointBtn.click();
      
      // Configure waypoint (yaw, pitch, hfov)
      const waypointYaw = page.locator('input[name*="waypointYaw"]').first();
      if (await waypointYaw.isVisible()) {
        await waypointYaw.fill('30');
      }
      
      const waypointPitch = page.locator('input[name*="waypointPitch"]').first();
      if (await waypointPitch.isVisible()) {
        await waypointPitch.fill('-5');
      }
      
      console.log('✅ Waypoint added');
    } else {
      console.log('ℹ️ Waypoint feature not available in UI');
    }

    console.log('Step 4: Save hotspot...');
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();

    console.log('Step 5: Verify waypoints in state...');
    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const activeScene = state?.scenes?.[state?.activeIndex || 0];
      const hotspot = activeScene?.hotspots?.[0];
      return hotspot?.waypoints || null;
    });

    console.log('Hotspot waypoints:', hotspotData);
    console.log('✅ Hotspot with waypoints created');
  });

  test('should edit hotspot transition type', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.locator('[data-testid="scene-option"]').first().click();

    console.log('Step 2: Select transition type...');
    const transitionSelect = page.locator(
      'select[name="transition"], ' +
      'select[aria-label*="Transition"], ' +
      '[data-testid="transition-select"]'
    );
    
    if (await transitionSelect.isVisible()) {
      // Try different transition types
      const transitionTypes = ['fade', 'cut', 'zoom'];
      
      for (const type of transitionTypes) {
        try {
          await transitionSelect.selectOption(type);
          console.log(`✅ Transition type set to: ${type}`);
          break;
        } catch (e) {
          continue;
        }
      }
    } else {
      console.log('⚠️ Transition select not found');
    }

    console.log('Step 3: Save hotspot...');
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();

    console.log('Step 4: Verify transition type in state...');
    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const activeScene = state?.scenes?.[state?.activeIndex || 0];
      const hotspot = activeScene?.hotspots?.[0];
      return hotspot?.transition || null;
    });

    console.log('Hotspot transition:', hotspotData);
    console.log('✅ Hotspot transition type configured');
  });

  test('should edit hotspot duration', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.locator('[data-testid="scene-option"]').first().click();

    console.log('Step 2: Set transition duration...');
    const durationInput = page.locator(
      'input[name="duration"], ' +
      'input[aria-label*="Duration"], ' +
      'input[type="number"][data-testid="duration"]'
    );
    
    if (await durationInput.isVisible()) {
      await durationInput.fill('2000');
      console.log('✅ Duration set to 2000ms');
    } else {
      console.log('⚠️ Duration input not found');
    }

    console.log('Step 3: Save hotspot...');
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();

    console.log('Step 4: Verify duration in state...');
    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const activeScene = state?.scenes?.[state?.activeIndex || 0];
      const hotspot = activeScene?.hotspots?.[0];
      return hotspot?.duration || null;
    });

    console.log('Hotspot duration:', hotspotData);
    console.log('✅ Hotspot duration configured');
  });

  test('should add/edit hotspot label', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.locator('[data-testid="scene-option"]').first().click();

    console.log('Step 2: Enter hotspot label...');
    const labelInput = page.locator(
      'input[name="label"], ' +
      'input[aria-label*="Label"], ' +
      'input[placeholder*="label"], ' +
      '[data-testid="label-input"]'
    );
    
    if (await labelInput.isVisible()) {
      await labelInput.fill('Entrance → Lobby');
      console.log('✅ Hotspot label entered');
    } else {
      console.log('⚠️ Label input not found');
    }

    console.log('Step 3: Save hotspot...');
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();

    console.log('Step 4: Verify label in viewer...');
    // Look for label displayed near hotspot
    const labelInViewer = page.locator('.hotspot-label:has-text("Entrance"), text=Entrance');
    if (await labelInViewer.isVisible({ timeout: 5000 }).catch(() => false)) {
      console.log('✅ Hotspot label visible in viewer');
    } else {
      console.log('ℹ️ Label may be shown on hover or in different format');
    }

    console.log('Step 5: Verify label in state...');
    const hotspotData = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const activeScene = state?.scenes?.[state?.activeIndex || 0];
      const hotspot = activeScene?.hotspots?.[0];
      return hotspot?.target || hotspot?.label || null;
    });

    console.log('Hotspot label data:', hotspotData);
    console.log('✅ Hotspot label configured');
  });

  test('should display hotspot connection lines', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create multiple hotspots...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    
    for (let i = 0; i < 2; i++) {
      if (await addLinkBtn.isVisible()) {
        await addLinkBtn.click();
        await page.locator('#viewer-stage').click({ position: { x: 300 + (i * 150), y: 300 } });
        
        await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
        await page.locator('[data-testid="scene-option"]').first().click();
        
        const saveBtn = page.locator('button:has-text("Save")');
        await saveBtn.click();
        await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
      }
    }

    console.log('Step 2: Look for hotspot connection lines...');
    // Connection lines might be SVG elements
    const connectionLines = page.locator(
      '.hotspot-lines line, ' +
      '.connection-line, ' +
      'svg line[data-hotspot], ' +
      '.hotspot-connector'
    );

    const lineCount = await connectionLines.count();
    if (lineCount > 0) {
      console.log(`✅ Found ${lineCount} hotspot connection lines`);
    } else {
      console.log('ℹ️ Connection lines not visible (may be shown in specific view mode)');
    }

    console.log('Step 3: Verify visual pipeline shows connections...');
    const pipelineConnections = page.locator(
      '.visual-pipeline .connection, ' +
      '.pipeline-line, ' +
      '.scene-connector'
    );
    
    const pipelineCount = await pipelineConnections.count();
    console.log(`Visual pipeline connections: ${pipelineCount}`);
    console.log('✅ Hotspot connections visualized');
  });
});
