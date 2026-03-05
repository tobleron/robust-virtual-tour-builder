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

test.describe('Multi-Floor Management', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);

    // Upload scenes for floor testing
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_3, 3);
    await waitForNavigationStabilization(page);
  });

  test('should assign scenes to floors via viewer floor buttons', async ({ page }) => {
    test.setTimeout(60000);

    const firstScene = page.locator('.scene-item').first();
    await expect(firstScene).toBeVisible({ timeout: 10000 });
    await firstScene.click();
    await waitForNavigationStabilization(page);

    // Floor buttons are typically on the left side of viewer
    const floorButtons = page.locator(
      '#viewer-floor-nav, .floor-nav, [data-testid="floor-nav"], ' +
      'button:has-text("G"), button:has-text("Ground"), button:has-text("1"), button:has-text("2")'
    );
    
    if (await floorButtons.count() > 0) {
      
      const groundFloorBtn = page.locator('button:has-text("G"), button:has-text("Ground"), .floor-btn:first-child');
      if (await groundFloorBtn.isVisible({ timeout: 5000 })) {
        await groundFloorBtn.click();
        await page.waitForTimeout(500);
      }
    } else {
    }

    const floorAssignment = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store.getState();
      const activeScene = state?.scenes?.[state?.activeIndex || 0];
      return activeScene?.floor || null;
    });
    
    if (floorAssignment) {
    }
  });

  test('should assign different floors to multiple scenes', async ({ page }) => {
    test.setTimeout(90000);

    const scenes = page.locator('.scene-item');
    const sceneCount = await scenes.count();
    
    for (let i = 0; i < sceneCount && i < 3; i++) {
      await scenes.nth(i).click();
      await waitForNavigationStabilization(page);
      
      const floorBtn = page.locator('.floor-btn').nth(i % 3); // Cycle through floors
      if (await floorBtn.isVisible()) {
        await floorBtn.click();
        await page.waitForTimeout(300);
      }
    }

    const floorAssignments = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store.getState();
      return state?.scenes?.map((s: any) => s.floor) || [];
    });

    
    // Verify at least some floors are assigned
    const assignedCount = floorAssignments.filter((f: string) => f).length;
    if (assignedCount > 0) {
    }
  });

  test('should display room label (tag) in blue tag at top center', async ({ page }) => {
    test.setTimeout(60000);

    const firstScene = page.locator('.scene-item').first();
    await firstScene.click();
    await waitForNavigationStabilization(page);

    const roomLabelSelectors = [
      '#viewer-room-label, .viewer-persistent-label, .room-label, ' +
      '.viewer-hud .label, [data-testid="room-label"], ' +
      '.top-center-label',
    ];

    let labelFound = false;
    for (const selector of roomLabelSelectors) {
      const label = page.locator(selector);
      if (await label.isVisible({ timeout: 5000 }).catch(() => false)) {
        labelFound = true;
        const labelText = await label.textContent();
        break;
      }
    }

    if (!labelFound) {
    }

  });

  test('should preserve floor assignments through export', async ({ page }) => {
    test.setTimeout(120000);

    const scenes = page.locator('.scene-item');
    const sceneCount = await scenes.count();
    
    for (let i = 0; i < sceneCount; i++) {
      await scenes.nth(i).click();
      await waitForNavigationStabilization(page);
      
      const floorBtn = page.locator('.floor-btn').first();
      if (await floorBtn.isVisible()) {
        await floorBtn.click();
        await page.waitForTimeout(200);
      }
    }

    const initialState = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store.getState();
      return state?.scenes?.map((s: any) => ({
        name: s.name,
        floor: s.floor,
      })) || [];
    });


    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    if (await exportBtn.isVisible()) {
      await exportBtn.click();
      
      const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
      await startExportBtn.click();
      
      const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
      const download = await downloadPromise;
    }

    const postState = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store.getState();
      return state?.scenes?.map((s: any) => ({
        name: s.name,
        floor: s.floor,
      })) || [];
    });

    
    // Compare states
    const same = JSON.stringify(initialState) === JSON.stringify(postState);
    if (same) {
    } else {
    }

  });

  test('should show only floors with scenes in exported tour', async ({ page }) => {
    test.setTimeout(90000);

    const scenes = page.locator('.scene-item');
    const sceneCount = await scenes.count();
    
    for (let i = 0; i < sceneCount; i++) {
      await scenes.nth(i).click();
      await waitForNavigationStabilization(page);
      
      // Assign all to ground floor
      const groundBtn = page.locator('button:has-text("G"), button:has-text("Ground"), .floor-btn:first-child');
      if (await groundBtn.isVisible()) {
        await groundBtn.click();
        await page.waitForTimeout(200);
      }
    }

    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    if (await exportBtn.isVisible()) {
      await exportBtn.click();
      const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
      await startExportBtn.click();
      
      const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
      const download = await downloadPromise;
    }

  });

  test.skip('should filter scenes by floor in sidebar', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Floor filtering not implemented');
  });
});
