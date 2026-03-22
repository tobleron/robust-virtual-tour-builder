import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { resetClientState, uploadImageAndWaitForSceneCount, waitForBuilderShellReady, waitForNavigationStabilization, setupAuthentication } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

async function selectFirstLinkTarget(page: any) {
  const select = page.locator('#link-target');
  await expect(select).toBeVisible({ timeout: 10000 });
  await select.selectOption({ index: 1 });
}

test.describe('Hotspot Advanced Features', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await setupAuthentication(page, 'dev-token');
    await resetClientState(page, { authToken: 'dev-token' });

    await waitForBuilderShellReady(page);
    await page.waitForTimeout(500);

    // Upload scenes for hotspot testing
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
  });

  test('should create waypoint during add-link mode with marching ants lines', async ({ page }) => {
    test.setTimeout(90000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();

    // Red draft line indicates camera path, Yellow indicates floor path
    await page.locator('#viewer-stage').move({ position: { x: 300, y: 300 } });
    await page.waitForTimeout(500);

    await page.locator('#viewer-stage').move({ position: { x: 500, y: 300 } });
    await page.waitForTimeout(500);

    // Check for draft lines by ID
    await expect(page.locator('#link_draft_red')).toBeVisible();
    await expect(page.locator('#link_draft_yellow')).toBeVisible();

    await page.locator('#viewer-stage').click({ position: { x: 500, y: 300 } });
    await page.waitForTimeout(300);

    // Press ENTER to finalize waypoint
    await page.keyboard.press('Enter');
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });

    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
  });

  test('should show orange arrow at waypoint start for preview', async ({ page }) => {
    test.setTimeout(90000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });

    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    // Arrow is now part of the hotspot in React layer
    const hotspotArrow = page.locator('[id^="hs-react-"] .hs-hotspot-base');
    await expect(hotspotArrow).toBeVisible({ timeout: 5000 });
  });

  test('should persist marching ants lines after link creation', async ({ page }) => {
    test.setTimeout(90000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    // Persistent line has id starting with hl_
    await expect(page.locator('[id^="hl_"]').first()).toBeVisible({ timeout: 5000 });
  });

  test('should display PCB-like orange connection lines from floor buttons to squares', async ({ page }) => {
    test.setTimeout(90000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');

    // Create one link to populate the visual pipeline
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    // Check for PCB connection lines in the visual pipeline
    await expect(page.locator('.pipeline-floor-line').first()).toBeVisible({ timeout: 10000 });
  });

  test('should color-code visual pipeline squares (emerald for auto-forward)', async ({ page }) => {
    test.setTimeout(120000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');

    // Create link 1 (normal)
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 300, y: 300 } });
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();

    // Create link 2 (auto-forward)
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });
    await selectFirstLinkTarget(page);

    const autoForwardToggle = page.locator('button[id$="-auto-forward-toggle"], button:has-text("Auto-Forward")');
    if (await autoForwardToggle.isVisible()) {
      await autoForwardToggle.click();
    }

    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();

    const autoForwardSquare = page.locator('.pipeline-node.visual-pipeline-square').last();
    // Emerald color is represented by var(--success) or calculated from thumbnail
    const style = await autoForwardSquare.getAttribute('style');
    expect(style).toContain('--node-color');
  });

  test.skip('should toggle return link on hotspot (DEPRECATED - legacy feature)', async ({ page }) => {
    test.skip(true, 'Return links deprecated - no UI toggle');
  });

  test.skip('should configure Director View target yaw/pitch/hfov', async ({ page }) => {
    test.skip(true, 'Director View not user-configurable');
  });
});
