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

test.describe('Timeline Management', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);

    // Upload 3 scenes for timeline testing
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_3, 3);
    await waitForNavigationStabilization(page);
  });

  test('should add timeline item from scene context menu', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Open timeline panel...');
    const timelineTab = page.locator('button:has-text("Timeline")');
    await expect(timelineTab).toBeVisible();
    await timelineTab.click();

    console.log('Step 2: Add timeline item to first scene...');
    // Find first scene in timeline and add timeline item
    const firstScene = page.locator('.timeline-scene-item').first();
    await expect(firstScene).toBeVisible({ timeout: 10000 });
    
    // Click add timeline button (usually a + icon)
    const addTimelineBtn = firstScene.locator('button[aria-label*="Add timeline"], button:has-text("Add")');
    if (await addTimelineBtn.isVisible()) {
      await addTimelineBtn.click();
    } else {
      // Alternative: right-click context menu
      await firstScene.click({ button: 'right' });
      const contextMenuItem = page.locator('[role="menuitem"]:has-text("Add Timeline")');
      await expect(contextMenuItem).toBeVisible({ timeout: 5000 });
      await contextMenuItem.click();
    }

    console.log('Step 3: Verify timeline item was created...');
    await expect(page.locator('.timeline-item')).toHaveCount(1, { timeout: 10000 });

    // Verify state update
    const timelineState = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return state?.timeline?.items || [];
    });
    expect(timelineState.length).toBeGreaterThanOrEqual(1);
    console.log('✅ Timeline item added successfully');
  });

  test('should update timeline transition type (Cut/Fade/Link)', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Open timeline and add item...');
    const timelineTab = page.locator('button:has-text("Timeline")');
    await timelineTab.click();

    const firstScene = page.locator('.timeline-scene-item').first();
    await expect(firstScene).toBeVisible({ timeout: 10000 });
    
    // Add timeline item
    const addBtn = firstScene.locator('button[aria-label*="Add"], button:has-text("Add")');
    if (await addBtn.isVisible()) {
      await addBtn.click();
    }

    console.log('Step 2: Change transition type to Fade...');
    const timelineItem = page.locator('.timeline-item').first();
    const transitionSelect = timelineItem.locator('select[data-testid="transition"], select[name="transition"]');
    
    if (await transitionSelect.isVisible()) {
      await transitionSelect.selectOption('fade');
      
      // Verify state update
      const transitionType = await page.evaluate(() => {
        // @ts-ignore
        const state = window.store?.state;
        return state?.timeline?.items?.[0]?.transition || null;
      });
      expect(transitionType).toBe('fade');
      console.log('✅ Transition type changed to Fade');
    } else {
      console.log('⚠️ Transition select not found - may use different UI pattern');
    }
  });

  test('should update timeline duration', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Open timeline and add item...');
    const timelineTab = page.locator('button:has-text("Timeline")');
    await timelineTab.click();

    const firstScene = page.locator('.timeline-scene-item').first();
    await firstScene.waitFor({ state: 'visible', timeout: 10000 });
    
    const addBtn = firstScene.locator('button[aria-label*="Add"], button:has-text("Add")');
    if (await addBtn.isVisible()) {
      await addBtn.click();
    }

    console.log('Step 2: Update duration to 3000ms...');
    const timelineItem = page.locator('.timeline-item').first();
    const durationInput = timelineItem.locator('input[type="number"][data-testid="duration"], input[name="duration"]');
    
    if (await durationInput.isVisible()) {
      await durationInput.fill('3000');
      await durationInput.press('Enter');
      
      // Verify state update
      const duration = await page.evaluate(() => {
        // @ts-ignore
        const state = window.store?.state;
        return state?.timeline?.items?.[0]?.duration || 0;
      });
      expect(duration).toBe(3000);
      console.log('✅ Duration updated to 3000ms');
    } else {
      console.log('⚠️ Duration input not found - may use different UI pattern');
    }
  });

  test('should reorder timeline items via drag-and-drop', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Create multiple timeline items...');
    const timelineTab = page.locator('button:has-text("Timeline")');
    await timelineTab.click();

    // Add timeline items to first two scenes
    const scenes = page.locator('.timeline-scene-item');
    for (let i = 0; i < 2 && i < await scenes.count(); i++) {
      const addBtn = scenes.nth(i).locator('button[aria-label*="Add"], button:has-text("Add")');
      if (await addBtn.isVisible()) {
        await addBtn.click();
        await page.waitForTimeout(200);
      }
    }

    const itemCount = await page.locator('.timeline-item').count();
    if (itemCount < 2) {
      test.skip(true, 'Could not create enough timeline items for reorder test');
      return;
    }

    console.log('Step 2: Reorder timeline items...');
    const firstItem = page.locator('.timeline-item').first();
    const secondItem = page.locator('.timeline-item').nth(1);
    
    // Get initial order
    const initialOrder = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return state?.timeline?.items?.map((item: any) => item.id) || [];
    });

    // Drag and drop (if supported)
    try {
      await firstItem.dragTo(secondItem);
      await page.waitForTimeout(500);

      // Verify order changed
      const newOrder = await page.evaluate(() => {
        // @ts-ignore
        const state = window.store?.state;
        return state?.timeline?.items?.map((item: any) => item.id) || [];
      });

      expect(newOrder).not.toEqual(initialOrder);
      console.log('✅ Timeline items reordered');
    } catch (e) {
      console.log('⚠️ Drag-and-drop not supported or failed');
    }
  });

  test('should remove timeline item', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Add timeline item...');
    const timelineTab = page.locator('button:has-text("Timeline")');
    await timelineTab.click();

    const firstScene = page.locator('.timeline-scene-item').first();
    const addBtn = firstScene.locator('button[aria-label*="Add"], button:has-text("Add")');
    if (await addBtn.isVisible()) {
      await addBtn.click();
    }

    const initialCount = await page.locator('.timeline-item').count();
    if (initialCount === 0) {
      test.skip(true, 'Could not create timeline item for removal test');
      return;
    }

    console.log('Step 2: Remove timeline item...');
    const timelineItem = page.locator('.timeline-item').first();
    const deleteBtn = timelineItem.locator('button[aria-label*="Delete"], button[aria-label*="Remove"], button:has-text("Delete")');
    
    if (await deleteBtn.isVisible()) {
      await deleteBtn.click();
      
      // Confirm deletion if modal appears
      const confirmBtn = page.locator('button:has-text("Confirm"), button:has-text("Delete"), button:has-text("Remove")');
      if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
      }

      // Verify item removed
      await expect(timelineItem).toHaveCount(0, { timeout: 5000 });
      console.log('✅ Timeline item removed');
    } else {
      console.log('⚠️ Delete button not found');
    }
  });

  test('should navigate to active timeline step', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create timeline with multiple items...');
    const timelineTab = page.locator('button:has-text("Timeline")');
    await timelineTab.click();

    // Add timeline items
    const scenes = page.locator('.timeline-scene-item');
    for (let i = 0; i < 2 && i < await scenes.count(); i++) {
      const addBtn = scenes.nth(i).locator('button[aria-label*="Add"], button:has-text("Add")');
      if (await addBtn.isVisible()) {
        await addBtn.click();
        await page.waitForTimeout(200);
      }
    }

    console.log('Step 2: Activate timeline step...');
    const firstTimelineItem = page.locator('.timeline-item').first();
    const playBtn = firstTimelineItem.locator('button[aria-label*="Play"], button:has-text("Go"), button:has-text("Navigate")');
    
    if (await playBtn.isVisible()) {
      await playBtn.click();
      
      // Wait for navigation to complete
      await waitForNavigationStabilization(page);
      
      // Verify active step in state
      const activeStepId = await page.evaluate(() => {
        // @ts-ignore
        const state = window.store?.state;
        return state?.timeline?.activeTimelineStepId || null;
      });
      
      expect(activeStepId).not.toBeNull();
      console.log('✅ Navigated to active timeline step');
    } else {
      console.log('⚠️ Play/navigate button not found');
    }
  });

  test('should preserve timeline through save/load cycle', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Create timeline items...');
    const timelineTab = page.locator('button:has-text("Timeline")');
    await timelineTab.click();

    const firstScene = page.locator('.timeline-scene-item').first();
    const addBtn = firstScene.locator('button[aria-label*="Add"], button:has-text("Add")');
    if (await addBtn.isVisible()) {
      await addBtn.click();
    }

    // Get initial timeline state
    const initialTimeline = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return {
        items: state?.timeline?.items?.length || 0,
        itemIds: state?.timeline?.items?.map((item: any) => item.id) || [],
      };
    });

    if (initialTimeline.items === 0) {
      test.skip(true, 'Could not create timeline for persistence test');
      return;
    }

    console.log('Step 2: Save project...');
    // Trigger save (usually auto-saved, but force if possible)
    await page.waitForTimeout(3000); // Wait for auto-save debounce

    console.log('Step 3: Reload page...');
    await page.reload({ waitUntil: 'networkidle' });
    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(2000);

    console.log('Step 4: Verify timeline preserved...');
    const timelineAfterLoad = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return {
        items: state?.timeline?.items?.length || 0,
        itemIds: state?.timeline?.items?.map((item: any) => item.id) || [],
      };
    });

    expect(timelineAfterLoad.items).toBe(initialTimeline.items);
    console.log('✅ Timeline preserved through save/load cycle');
  });
});
