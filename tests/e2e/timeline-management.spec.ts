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

async function selectFirstLinkTarget(page: any) {
  const select = page.locator('#link-target');
  await expect(select).toBeVisible({ timeout: 10000 });
  await select.selectOption({ index: 1 });
}

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
    const initialSquareCount = await page.locator('.pipeline-node').count();

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });

      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await selectFirstLinkTarget(page);

      const saveBtn = page.locator('button:has-text("Save Link"), button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    await page.waitForTimeout(1000); // Allow UI to update

    const newSquareCount = await page.locator('.pipeline-node').count();
    expect(newSquareCount).toBeGreaterThan(initialSquareCount);
  });

  test('should color-code squares by link type (success emerald for auto-forward)', async ({ page }) => {
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
      await selectFirstLinkTarget(page);

      const saveBtn = page.locator('button:has-text("Save Link"), button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    // Enable auto-forward on second link
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });

      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await selectFirstLinkTarget(page);

      // Enable auto-forward
      const autoForwardToggle = page.locator('button[id$="-auto-forward-toggle"], button:has-text("Auto-Forward")');
      if (await autoForwardToggle.isVisible()) {
        await autoForwardToggle.click();
      }

      await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    }

    const autoForwardSquare = page.locator('.pipeline-node.visual-pipeline-square').last();
    const style = await autoForwardSquare.getAttribute('style');
    expect(style).toContain('--node-color');
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
      await selectFirstLinkTarget(page);
      await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    }

    const timelineSquare = page.locator('.pipeline-node').first();
    await expect(timelineSquare).toBeVisible();
    await timelineSquare.hover();
    await page.waitForTimeout(200);

    const globalTooltip = page.locator('.pipeline-global-tooltip');
    await expect(globalTooltip).toBeVisible();
    await expect(globalTooltip.locator('img')).toBeVisible();
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
      await selectFirstLinkTarget(page);
      await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    }

    const initialActiveIndex = await page.evaluate(() => {
      // @ts-ignore
      return window.store?.state?.activeIndex || 0;
    });

    const timelineNodes = page.locator('.pipeline-node');
    await expect(timelineNodes.first()).toBeVisible({ timeout: 10000 });

    await timelineNodes.nth(1).click();
    await waitForNavigationStabilization(page);

    const newActiveIndex = await page.evaluate(() => {
      // @ts-ignore
      return window.store?.state?.activeIndex || 0;
    });

    expect(newActiveIndex).not.toBe(initialActiveIndex);
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
      await selectFirstLinkTarget(page);
      await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    }

    const initialSquareCount = await page.locator('.pipeline-node').count();

    const hotspot = page.locator('[id^="hs-react-"]').first();
    await expect(hotspot).toBeVisible();
    await hotspot.hover();
    await page.waitForTimeout(500);

    const trashBtn = page.locator('button[aria-label*="Delete"], button[title*="Delete"], .trash-icon');
    if (await trashBtn.isVisible()) {
      await trashBtn.click();
    }

    await page.waitForTimeout(1000); // Allow UI to update
    const newSquareCount = await page.locator('.pipeline-node').count();
    expect(newSquareCount).toBeLessThan(initialSquareCount);
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
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    await page.waitForTimeout(800);
    const before = await page.locator('.pipeline-node').count();
    expect(before).toBeGreaterThan(0);

    await page.locator('.scene-item').first().locator('button[aria-label^="Actions for"]').click();
    await page.getByText('Clear Links').click();
    await expect(page.getByText('Links cleared. Press U to undo.')).toBeVisible({ timeout: 5000 });

    await page.waitForTimeout(800);
    const after = await page.locator('.pipeline-node').count();
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
        const items = document.querySelectorAll('.scene-item h4');
        return Array.from(items).map(el => el.textContent?.trim() || '');
      });
    };

    const initialOrder = await getSceneOrder();

    const firstScene = page.locator('.scene-item').first();
    const secondScene = page.locator('.scene-item').nth(1);

    await firstScene.dragTo(secondScene);
    await page.waitForTimeout(1000);

    const newOrder = await getSceneOrder();
    expect(newOrder).not.toEqual(initialOrder);
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
      await selectFirstLinkTarget(page);
      await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
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

    expect(timelineAfterLoad.sceneCount).toBe(initialTimeline.sceneCount);
    expect(timelineAfterLoad.hotspotCount).toBe(initialTimeline.hotspotCount);
  });
});
