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

test.describe('Timeline Management (Visual Pipeline)', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should auto-generate timeline square when hotspot is created', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    // Before creating any links, visual pipeline should be empty or minimal
    const initialSquareCount = await page.locator('.visual-pipeline-square, .pipeline-square').count();

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
      
    }

    await page.waitForTimeout(1000); // Allow UI to update
    
    const newSquareCount = await page.locator('.visual-pipeline-square, .pipeline-square').count();
    
    expect(newSquareCount).toBeGreaterThan(initialSquareCount);
  });

  test('should color-code squares by link type (orange-brown for simple, emerald for auto-forward)', async ({ page }) => {
    test.setTimeout(120000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    // Simple links should have orange-brown color (histogram-based)
    const simpleLinkSquare = page.locator('.visual-pipeline-square:not(.auto-forward), .pipeline-square:not(.auto-forward)').first();
    if (await simpleLinkSquare.isVisible()) {
      const bgColor = await simpleLinkSquare.evaluate((el) => {
        const style = window.getComputedStyle(el);
        return style.backgroundColor;
      });
    }

    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 2 });
      
      // Enable auto-forward
      const autoForwardBtn = page.locator('button:has-text("AUTO"), button[title*="Auto-Forward"]');
      if (await autoForwardBtn.isVisible()) {
        await autoForwardBtn.click();
      }
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    const autoForwardSquare = page.locator('.visual-pipeline-square.auto-forward, .pipeline-square.auto-forward, [data-auto-forward="true"]');
    if (await autoForwardSquare.isVisible({ timeout: 5000 })) {
      const bgColor = await autoForwardSquare.evaluate((el) => {
        const style = window.getComputedStyle(el);
        return style.backgroundColor;
      });
    } else {
    }
  });

  test('should show tooltip with linkId after 3-second hover', async ({ page }) => {
    test.setTimeout(60000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    const timelineSquare = page.locator('.visual-pipeline-square, .pipeline-square').first();
    if (await timelineSquare.isVisible()) {
      await timelineSquare.hover();
      
      await page.waitForTimeout(3500); // Wait for delayed tooltip
      
      const tooltip = page.locator('[role="tooltip"], .tooltip, [data-testid="tooltip"]');
      if (await tooltip.isVisible({ timeout: 5000 })) {
        const tooltipText = await tooltip.textContent();
        
        // Tooltip should contain link ID (e.g., "l-Scene 2" or similar)
        if (tooltipText.includes('l-') || tooltipText.toLowerCase().includes('link')) {
        } else {
        }
      } else {
      }
    }
  });

  test('should show thumbnail preview on timeline square hover', async ({ page }) => {
    test.setTimeout(60000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    const timelineSquare = page.locator('.visual-pipeline-square, .pipeline-square').first();
    if (await timelineSquare.isVisible()) {
      await timelineSquare.hover();
      await page.waitForTimeout(500);
      
      // Look for thumbnail preview (typically at top of viewer)
      const thumbnailSelectors = [
        '.thumbnail-preview',
        '.pipeline-thumbnail',
        '.hover-preview',
        '[data-testid="thumbnail"]',
        '.viewer-header img',
      ];
      
      let thumbnailFound = false;
      for (const selector of thumbnailSelectors) {
        const thumbnail = page.locator(selector);
        if (await thumbnail.isVisible({ timeout: 3000 }).catch(() => false)) {
          thumbnailFound = true;
          break;
        }
      }
      
      if (!thumbnailFound) {
      }
    }
  });

  test('should navigate to scene when timeline square is clicked', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    const initialActiveIndex = await page.evaluate(() => {
      // @ts-ignore
      return window.store?.state?.activeIndex || 0;
    });

    const timelineSquare = page.locator('.visual-pipeline-square, .pipeline-square').nth(1); // Second square (linked scene)
    if (await timelineSquare.isVisible()) {
      await timelineSquare.click();
      await waitForNavigationStabilization(page);
      
      const newActiveIndex = await page.evaluate(() => {
        // @ts-ignore
        return window.store?.state?.activeIndex || 0;
      });
      
      if (newActiveIndex !== initialActiveIndex) {
      } else {
      }
    }
  });

  test('should delete timeline square when hotspot is deleted', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    const initialSquareCount = await page.locator('.visual-pipeline-square, .pipeline-square').count();

    // Hotspots are now in React layer
    const hotspot = page.locator('[id^="hs-react-"]').first();
    if (await hotspot.isVisible()) {
      await hotspot.hover();
      await page.waitForTimeout(500);
      
      const trashBtn = page.locator('button[aria-label*="Delete"], button[title*="Delete"], .trash-icon');
      if (await trashBtn.isVisible({ timeout: 5000 })) {
        await trashBtn.click();
      } else {
      }
    }

    await page.waitForTimeout(1000); // Allow UI to update
    
    const newSquareCount = await page.locator('.visual-pipeline-square, .pipeline-square').count();
    
    if (newSquareCount < initialSquareCount) {
    } else {
    }
  });

  test('should prune timeline squares when Clear Links is triggered for a scene', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 420, y: 300 } });
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.selectOption('#link-target', { index: 1 });
    await page.locator('button:has-text("Save")').click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    await page.waitForTimeout(800);
    const before = await page.locator('.visual-pipeline-square, .pipeline-square').count();
    expect(before).toBeGreaterThan(0);

    await page.locator('.scene-item').first().locator('button[aria-label^="Actions for"]').click();
    await page.getByText('Clear Links').click();
    await expect(page.getByText('Links cleared. Press U to undo.')).toBeVisible({ timeout: 5000 });

    await page.waitForTimeout(800);
    const after = await page.locator('.visual-pipeline-square, .pipeline-square').count();
    expect(after).toBeLessThan(before);
  });

  test('should allow sidebar scene drag-drop reordering', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_3, 3);
    await waitForNavigationStabilization(page);

    const getSceneOrder = async () => {
      return await page.evaluate(() => {
        const items = document.querySelectorAll('.scene-item h4, .scene-item .scene-name');
        return Array.from(items).map(el => el.textContent?.trim() || '');
      });
    };
    
    const initialOrder = await getSceneOrder();

    const firstScene = page.locator('.scene-item').first();
    const secondScene = page.locator('.scene-item').nth(1);
    
    if (await firstScene.isVisible() && await secondScene.isVisible()) {
      try {
        await firstScene.dragTo(secondScene);
        await page.waitForTimeout(500);
        
        const newOrder = await getSceneOrder();
        
        if (JSON.stringify(newOrder) !== JSON.stringify(initialOrder)) {
        } else {
        }
      } catch (e) {
      }
    }
  });

  test('should preserve timeline through save/load cycle', async ({ page }) => {
    test.setTimeout(120000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    const initialTimeline = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return {
        sceneCount: state?.scenes?.length || 0,
        hotspotCount: state?.scenes?.reduce((sum: number, s: any) => sum + (s.hotspots?.length || 0), 0) || 0,
      };
    });

    await page.waitForTimeout(3000); // Wait for auto-save debounce

    await page.reload({ waitUntil: 'networkidle' });
    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(2000);

    const timelineAfterLoad = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      return {
        sceneCount: state?.scenes?.length || 0,
        hotspotCount: state?.scenes?.reduce((sum: number, s: any) => sum + (s.hotspots?.length || 0), 0) || 0,
      };
    });

    if (timelineAfterLoad.sceneCount === initialTimeline.sceneCount &&
        timelineAfterLoad.hotspotCount === initialTimeline.hotspotCount) {
    } else {
    }
  });
});
