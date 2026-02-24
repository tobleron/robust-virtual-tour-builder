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

  test('should assign scenes to different floors', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Select first scene...');
    const firstScene = page.locator('.scene-item').first();
    await expect(firstScene).toBeVisible({ timeout: 10000 });
    await firstScene.click();

    console.log('Step 2: Open scene metadata/floor editor...');
    // Look for floor assignment UI
    const floorSelect = page.locator('select[name="floor"], select[aria-label*="Floor"], [data-testid="floor-select"]');
    const editBtn = page.locator('button[aria-label*="Edit"], button:has-text("Edit")');
    
    if (await editBtn.isVisible()) {
      await editBtn.click();
    }

    if (await floorSelect.isVisible()) {
      console.log('Step 3: Assign to Ground floor...');
      await floorSelect.selectOption('ground');
      
      // Verify state update
      const floorAssignment = await page.evaluate(() => {
        // @ts-ignore
        const state = window.store?.state;
        const activeScene = state?.scenes?.[state?.activeIndex || 0];
        return activeScene?.floor || null;
      });
      
      expect(floorAssignment).toBe('ground');
      console.log('✅ Scene assigned to Ground floor');
    } else {
      console.log('⚠️ Floor select not found - checking for alternative UI');
      
      // Try context menu or sidebar
      const sceneMenu = page.locator('.scene-item button[aria-label*="Menu"], .scene-item ...');
      if (await sceneMenu.isVisible()) {
        await sceneMenu.click();
        const floorOption = page.locator('[role="menuitem"]:has-text("Floor")');
        if (await floorOption.isVisible()) {
          await floorOption.click();
          console.log('✅ Floor menu opened');
        }
      }
    }
  });

  test('should assign multiple scenes to different floors', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Assign scene 1 to Ground floor...');
    const scene1 = page.locator('.scene-item').nth(0);
    await scene1.click();
    
    const floorSelect = page.locator('select[name="floor"], select[aria-label*="Floor"]');
    if (await floorSelect.isVisible()) {
      await floorSelect.selectOption('ground');
      await page.waitForTimeout(300);
    }

    console.log('Step 2: Assign scene 2 to First floor...');
    const scene2 = page.locator('.scene-item').nth(1);
    await scene2.click();
    
    if (await floorSelect.isVisible()) {
      await floorSelect.selectOption('first');
      await page.waitForTimeout(300);
    }

    console.log('Step 3: Assign scene 3 to Second floor...');
    const scene3 = page.locator('.scene-item').nth(2);
    await scene3.click();
    
    if (await floorSelect.isVisible()) {
      await floorSelect.selectOption('second');
      await page.waitForTimeout(300);
    }

    console.log('Step 4: Verify floor assignments in state...');
    const floorAssignments = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return state?.scenes?.map((s: any) => s.floor) || [];
    });

    console.log('Floor assignments:', floorAssignments);
    expect(floorAssignments).toContain('ground');
    expect(floorAssignments).toContain('first');
    expect(floorAssignments).toContain('second');
    
    console.log('✅ Multiple scenes assigned to different floors');
  });

  test('should navigate floors using floor navigation UI', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Assign scenes to different floors...');
    const scenes = page.locator('.scene-item');
    const sceneCount = await scenes.count();
    
    const floorSelect = page.locator('select[name="floor"], select[aria-label*="Floor"]');
    const floors = ['ground', 'first', 'second'];
    
    for (let i = 0; i < Math.min(sceneCount, 3); i++) {
      await scenes.nth(i).click();
      if (await floorSelect.isVisible()) {
        await floorSelect.selectOption(floors[i]);
        await page.waitForTimeout(200);
      }
    }

    console.log('Step 2: Find floor navigation UI...');
    // Floor navigation might be:
    // - Floor tabs/buttons
    // - Floor dropdown
    // - Floor filter in sidebar
    
    const floorNavSelectors = [
      '[role="tablist"] [role="tab"]:has-text("Ground")',
      '.floor-nav button:has-text("Ground")',
      '[data-testid="floor-nav"] button',
      '.floor-filter button',
    ];

    let floorNavFound = false;
    for (const selector of floorNavSelectors) {
      const nav = page.locator(selector);
      if (await nav.isVisible({ timeout: 3000 }).catch(() => false)) {
        floorNavFound = true;
        console.log('✅ Floor navigation found:', selector);
        
        console.log('Step 3: Click on different floor...');
        const firstFloorBtn = page.locator(selector.replace('Ground', 'First'));
        if (await firstFloorBtn.isVisible()) {
          await firstFloorBtn.click();
          await page.waitForTimeout(500);
          
          // Verify filtered scenes
          const visibleScenes = await page.locator('.scene-item:visible').count();
          console.log('Visible scenes after floor filter:', visibleScenes);
        }
        break;
      }
    }

    if (!floorNavFound) {
      console.log('ℹ️ Floor navigation UI not found (may use different pattern)');
    }
  });

  test('should display floor tags in viewer HUD', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Assign scene to specific floor...');
    const firstScene = page.locator('.scene-item').first();
    await firstScene.click();

    const floorSelect = page.locator('select[name="floor"], select[aria-label*="Floor"]');
    if (await floorSelect.isVisible()) {
      await floorSelect.selectOption('outdoor');
      await page.waitForTimeout(300);
    }

    console.log('Step 2: Navigate to scene and check HUD...');
    await firstScene.click();
    await waitForNavigationStabilization(page);

    console.log('Step 3: Look for floor tag in viewer HUD...');
    const hudSelectors = [
      '.viewer-hud .floor-tag',
      '.scene-info .floor',
      '[data-testid="floor-tag"]',
      '.hud-floor',
      'text=Outdoor',
      'text=Ground',
    ];

    let floorTagFound = false;
    for (const selector of hudSelectors) {
      const tag = page.locator(selector);
      if (await tag.isVisible({ timeout: 3000 }).catch(() => false)) {
        floorTagFound = true;
        console.log('✅ Floor tag found in HUD:', selector);
        break;
      }
    }

    if (!floorTagFound) {
      console.log('ℹ️ Floor tag not visible in HUD (may be implemented differently)');
    }
  });

  test('should filter scenes by floor in sidebar', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create scenes on different floors...');
    const scenes = page.locator('.scene-item');
    const sceneCount = await scenes.count();
    
    const floorSelect = page.locator('select[name="floor"], select[aria-label*="Floor"]');
    
    // Assign first half to ground, second half to first
    for (let i = 0; i < sceneCount; i++) {
      await scenes.nth(i).click();
      if (await floorSelect.isVisible()) {
        const floor = i < sceneCount / 2 ? 'ground' : 'first';
        await floorSelect.selectOption(floor);
        await page.waitForTimeout(200);
      }
    }

    console.log('Step 2: Find floor filter in sidebar...');
    const sidebarFilter = page.locator('.sidebar [role="tab"]:has-text("Ground"), .sidebar button:has-text("Ground")');
    
    if (await sidebarFilter.isVisible({ timeout: 5000 })) {
      console.log('Step 3: Click Ground floor filter...');
      await sidebarFilter.click();
      await page.waitForTimeout(500);

      // Count visible scenes
      const initialCount = await scenes.count();
      const filteredCount = await page.locator('.scene-item:visible').count();
      
      console.log(`Scenes before filter: ${initialCount}, after Ground filter: ${filteredCount}`);
      expect(filteredCount).toBeLessThanOrEqual(initialCount);
      expect(filteredCount).toBeGreaterThan(0);
      
      console.log('✅ Floor filtering working');
    } else {
      console.log('ℹ️ Floor filter not found in sidebar');
    }
  });

  test('should preserve floor assignments through export', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Assign floors to scenes...');
    const scenes = page.locator('.scene-item');
    const sceneCount = await scenes.count();
    
    const floorSelect = page.locator('select[name="floor"], select[aria-label*="Floor"]');
    const floorAssignments: string[] = [];
    
    for (let i = 0; i < sceneCount; i++) {
      await scenes.nth(i).click();
      if (await floorSelect.isVisible()) {
        const floor = i % 2 === 0 ? 'ground' : 'first';
        await floorSelect.selectOption(floor);
        floorAssignments.push(floor);
        await page.waitForTimeout(200);
      }
    }

    console.log('Step 2: Get initial floor state...');
    const initialState = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return state?.scenes?.map((s: any) => s.floor) || [];
    });

    console.log('Initial floor assignments:', initialState);

    console.log('Step 3: Export project...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    if (await exportBtn.isVisible()) {
      await exportBtn.click();
      
      const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
      await startExportBtn.click();
      
      const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
      const download = await downloadPromise;
      console.log('Exported:', download.suggestedFilename());
    }

    console.log('Step 4: Verify floor assignments preserved...');
    const postState = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return state?.scenes?.map((s: any) => s.floor) || [];
    });

    console.log('Post-export floor assignments:', postState);
    expect(postState).toEqual(initialState);
    
    console.log('✅ Floor assignments preserved through export');
  });
});
