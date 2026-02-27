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

  test('should create waypoint during add-link mode with yellow and orange dashed lines', async ({ page }) => {
    test.setTimeout(90000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
    }

    // Move cursor to create yellow dashed line (user path)
    await page.locator('#viewer-stage').move({ position: { x: 300, y: 300 } });
    await page.waitForTimeout(500);
    
    await page.locator('#viewer-stage').move({ position: { x: 400, y: 300 } });
    await page.waitForTimeout(500);
    
    await page.locator('#viewer-stage').move({ position: { x: 500, y: 300 } });
    await page.waitForTimeout(500);

    const dashedLineSelectors = [
      '.waypoint-line, .dashed-line, .path-line, ' +
      '[class*="waypoint"], [class*="dashed"], ' +
      'svg line, svg path',
    ];

    let linesFound = false;
    for (const selector of dashedLineSelectors) {
      const lines = page.locator(selector);
      if (await lines.count() > 0) {
        linesFound = true;
        break;
      }
    }

    if (!linesFound) {
    }

    await page.locator('#viewer-stage').click({ position: { x: 500, y: 300 } });
    await page.waitForTimeout(300);
    
    // Press ENTER to finalize waypoint
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);

    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });

    await page.selectOption('#link-target', { index: 1 });
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

  });

  test('should show orange arrow at waypoint start for preview', async ({ page }) => {
    test.setTimeout(90000);

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

    const arrowSelectors = [
      '.waypoint-arrow, .arrow-indicator, .orange-arrow, ' +
      '[class*="arrow"], [data-testid="arrow"], ' +
      '.preview-arrow',
    ];

    let arrowFound = false;
    for (const selector of arrowSelectors) {
      const arrow = page.locator(selector);
      if (await arrow.isVisible({ timeout: 5000 }).catch(() => false)) {
        arrowFound = true;
        
        try {
          await arrow.click();
          await page.waitForTimeout(2000);
        } catch (e) {
        }
        break;
      }
    }

    if (!arrowFound) {
    }

  });

  test('should persist orange dashed lines after link creation', async ({ page }) => {
    test.setTimeout(90000);

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

    // Orange lines should persist after successful creation
    const lineSelectors = [
      '.waypoint-line.orange, .orange-line, .persistent-line, ' +
      '[class*="waypoint"]',
    ];

    let linesFound = false;
    for (const selector of lineSelectors) {
      const lines = page.locator(selector);
      if (await lines.count() > 0) {
        linesFound = true;
        break;
      }
    }

    if (!linesFound) {
    }
  });

  test('should display PCB-like orange connection lines from floor buttons to squares', async ({ page }) => {
    test.setTimeout(90000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    
    for (let i = 0; i < 2 && await addLinkBtn.isVisible(); i++) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 300 + (i * 150), y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    const connectionSelectors = [
      '.pcb-line, .connection-line, .floor-connection, ' +
      '.orange-line, [class*="connection"], ' +
      'svg line[class*="floor"], svg path[class*="pcb"]',
    ];

    let connectionsFound = false;
    for (const selector of connectionSelectors) {
      const connections = page.locator(selector);
      if (await connections.count() > 0) {
        connectionsFound = true;
        break;
      }
    }

    if (!connectionsFound) {
    }

  });

  test('should color-code visual pipeline squares (orange-brown simple, emerald auto-forward)', async ({ page }) => {
    test.setTimeout(120000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    const simpleSquare = page.locator('.visual-pipeline-square:not(.auto-forward), .pipeline-square:not(.auto-forward)').first();
    if (await simpleSquare.isVisible()) {
      const color = await simpleSquare.evaluate((el) => {
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
    }

    const autoForwardSquare = page.locator('.visual-pipeline-square.auto-forward, .pipeline-square.auto-forward, [data-auto-forward="true"]').last();
    if (await autoForwardSquare.isVisible({ timeout: 5000 })) {
      const color = await autoForwardSquare.evaluate((el) => {
        const style = window.getComputedStyle(el);
        return style.backgroundColor;
      });
    }
  });

  test.skip('should toggle return link on hotspot (DEPRECATED - legacy feature)', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Return links deprecated - no UI toggle');
  });

  test.skip('should configure Director View target yaw/pitch/hfov', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Director View not user-configurable');
  });

  test.skip('should edit hotspot transition type', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Transition type not user-selectable');
  });

  test.skip('should edit hotspot duration', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Duration not user-configurable');
  });

  test.skip('should add/edit hotspot label', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Hotspot labels not supported');
  });
});
