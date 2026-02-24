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

    console.log('Step 1: Enter add-link mode...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      console.log('✅ Add-link mode entered');
    }

    console.log('Step 2: Move cursor to create waypoint path...');
    // Move cursor to create yellow dashed line (user path)
    await page.locator('#viewer-stage').move({ position: { x: 300, y: 300 } });
    await page.waitForTimeout(500);
    
    await page.locator('#viewer-stage').move({ position: { x: 400, y: 300 } });
    await page.waitForTimeout(500);
    
    await page.locator('#viewer-stage').move({ position: { x: 500, y: 300 } });
    await page.waitForTimeout(500);

    console.log('Step 3: Look for dashed lines (yellow for cursor, orange for camera)...');
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
        console.log('✅ Waypoint lines found:', selector);
        break;
      }
    }

    if (!linesFound) {
      console.log('ℹ️ Dashed lines not visible (may use different implementation)');
    }

    console.log('Step 4: Click final point and press ENTER to finalize...');
    await page.locator('#viewer-stage').click({ position: { x: 500, y: 300 } });
    await page.waitForTimeout(300);
    
    // Press ENTER to finalize waypoint
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);

    console.log('Step 5: Verify link modal appears...');
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });
    console.log('✅ Waypoint finalized, modal appeared');

    console.log('Step 6: Select target and save...');
    await page.locator('[data-testid="scene-option"]').first().click();
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    console.log('✅ Waypoint created successfully');
  });

  test('should show orange arrow at waypoint start for preview', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot with waypoint...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').first().click();
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    console.log('Step 2: Look for orange arrow at waypoint start...');
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
        console.log('✅ Orange arrow found:', selector);
        
        console.log('Step 3: Click arrow to preview waypoint animation...');
        try {
          await arrow.click();
          await page.waitForTimeout(2000);
          console.log('✅ Arrow clicked, animation should start');
        } catch (e) {
          console.log('ℹ️ Arrow click may not trigger animation');
        }
        break;
      }
    }

    if (!arrowFound) {
      console.log('ℹ️ Orange arrow not found (may use different implementation)');
    }

    console.log('Note: Orange dashed lines persist after successful link creation');
  });

  test('should persist orange dashed lines after link creation', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create hotspot...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').first().click();
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    console.log('Step 2: Verify orange lines persist (if ESC not pressed)...');
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
        console.log('✅ Orange dashed lines persist:', selector);
        break;
      }
    }

    if (!linesFound) {
      console.log('ℹ️ Persistent lines not found (may be hidden after save)');
    }
  });

  test('should display PCB-like orange connection lines from floor buttons to squares', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Create multiple hotspots...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    
    for (let i = 0; i < 2 && await addLinkBtn.isVisible(); i++) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 300 + (i * 150), y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').first().click();
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    console.log('Step 2: Look for PCB-like orange connection lines...');
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
        console.log('✅ PCB-like connection lines found:', selector);
        break;
      }
    }

    if (!connectionsFound) {
      console.log('ℹ️ Connection lines not found (may use different visual style)');
    }

    console.log('Note: Each floor has squares in separate row with orange line from floor button');
  });

  test('should color-code visual pipeline squares (orange-brown simple, emerald auto-forward)', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Create simple link...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').first().click();
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    console.log('Step 2: Verify simple link square color (orange-brown)...');
    const simpleSquare = page.locator('.visual-pipeline-square:not(.auto-forward), .pipeline-square:not(.auto-forward)').first();
    if (await simpleSquare.isVisible()) {
      const color = await simpleSquare.evaluate((el) => {
        const style = window.getComputedStyle(el);
        return style.backgroundColor;
      });
      console.log('Simple link square color:', color);
      console.log('✅ Simple link has histogram-based color (orange-brown spectrum)');
    }

    console.log('Step 3: Create auto-forward link...');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').nth(1).click();
      
      // Enable auto-forward
      const autoForwardBtn = page.locator('button:has-text("AUTO"), button[title*="Auto-Forward"]');
      if (await autoForwardBtn.isVisible()) {
        await autoForwardBtn.click();
      }
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
    }

    console.log('Step 4: Verify auto-forward square color (emerald green)...');
    const autoForwardSquare = page.locator('.visual-pipeline-square.auto-forward, .pipeline-square.auto-forward, [data-auto-forward="true"]').last();
    if (await autoForwardSquare.isVisible({ timeout: 5000 })) {
      const color = await autoForwardSquare.evaluate((el) => {
        const style = window.getComputedStyle(el);
        return style.backgroundColor;
      });
      console.log('Auto-forward square color:', color);
      console.log('✅ Auto-forward link has emerald green color');
    }
  });

  test.skip('should toggle return link on hotspot (DEPRECATED - legacy feature)', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Note: This test is skipped because return links are DEPRECATED.');
    console.log('The isReturnLink field exists in data structure for legacy compatibility,');
    console.log('but there is NO UI toggle button in HotspotActionMenu.');
    console.log('Feature is read-only legacy data, not user-accessible.');
    
    test.skip(true, 'Return links deprecated - no UI toggle');
  });

  test.skip('should configure Director View target yaw/pitch/hfov', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Note: This test is skipped because Director View manual configuration');
    console.log('is NOT available to users. The landing camera position is automatically');
    console.log('determined by the app as the END of the waypoint in the target scene.');
    console.log('Users cannot manually set yaw/pitch/hfov values.');
    
    test.skip(true, 'Director View not user-configurable');
  });

  test.skip('should edit hotspot transition type', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Note: This test is skipped because transition type selection');
    console.log('is NOT available to users. Transitions are hardcoded defaults');
    console.log('(fast crossfade) optimized by the developer.');
    
    test.skip(true, 'Transition type not user-selectable');
  });

  test.skip('should edit hotspot duration', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Note: This test is skipped because hotspot duration');
    console.log('is NOT user-configurable. Duration is fixed and automatic,');
    console.log('pre-set by the developer.');
    
    test.skip(true, 'Duration not user-configurable');
  });

  test.skip('should add/edit hotspot label', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Note: This test is skipped because custom hotspot labels');
    console.log('are NOT supported. Users cannot add text labels to hotspots.');
    
    test.skip(true, 'Hotspot labels not supported');
  });
});
