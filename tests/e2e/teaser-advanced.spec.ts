import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import {
  resetClientState,
  uploadImageAndWaitForSceneCount,
  waitForBuilderShellReady,
  waitForNavigationStabilization,
  setupAuthentication,
} from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

test.describe('Teaser Advanced Features', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await setupAuthentication(page, 'dev-token');
    await resetClientState(page, { authToken: 'dev-token' });

    await waitForBuilderShellReady(page);
    await page.waitForTimeout(500);
  });

  async function selectFirstLinkTarget(page: any) {
    const select = page.locator('#link-target');
    await expect(select).toBeVisible({ timeout: 10000 });
    await select.selectOption({ index: 1 });
  }

  async function prepareThreeHotspots(page: any) {
    // Reset and upload first scene
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);

    // Upload second scene
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    // Create 3 hotspots (2 links) to meet teaserReady requirement (totalHotspots >= 3)
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');

    // Link 1
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 300, y: 300 } });
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await page.waitForTimeout(500);

    // Link 2
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 500, y: 300 } });
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await page.waitForTimeout(500);

    // Link 3
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 500 } });
    await selectFirstLinkTarget(page);
    await page.locator('button:has-text("Save Link"), button:has-text("Save")').click();
    await page.waitForTimeout(1000);
  }

  test('should use Cinematic style (default, only working style)', async ({ page }) => {
    test.setTimeout(180000);

    await prepareThreeHotspots(page);

    const teaserBtn = page.locator('button[aria-label="Create Teaser"]');
    await expect(teaserBtn).toBeVisible({ timeout: 10000 });
    await teaserBtn.click();

    const styleModal = page.locator('.modal-teaser-style');
    await expect(styleModal).toBeVisible();
    await styleModal.getByText('Cinematic').click();

    // Expect the processing card to appear
    const processingCard = page.locator('.sidebar-processing-card');
    await expect(processingCard).toBeVisible({ timeout: 15000 });

    // Wait for the download event, which signifies completion
    const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toContain('.webm');
  });

  test('should cancel teaser recording via cancel button', async ({ page }) => {
    test.setTimeout(90000);

    await prepareThreeHotspots(page);

    const teaserBtn = page.locator('button[aria-label="Create Teaser"]');
    await teaserBtn.click();

    const styleModal = page.locator('.modal-teaser-style');
    await expect(styleModal).toBeVisible();
    await styleModal.getByText('Cinematic').click();

    const processingCard = page.locator('.sidebar-processing-card');
    await expect(processingCard).toBeVisible({ timeout: 15000 });

    const cancelBtn = processingCard.locator('button:has-text("Cancel")');
    await cancelBtn.click();

    await expect(processingCard).toBeHidden({ timeout: 10000 });
  });

  test('should display teaser progress bar with percentage', async ({ page }) => {
    test.setTimeout(120000);

    await prepareThreeHotspots(page);

    const teaserBtn = page.locator('button[aria-label="Create Teaser"]');
    await teaserBtn.click();
    await page.locator('.modal-teaser-style').getByText('Cinematic').click();

    const processingCard = page.locator('.sidebar-processing-card');
    const pctLabel = processingCard.locator('.sidebar-progress-percentage');

    await expect(pctLabel).toBeVisible({ timeout: 15000 });
    const text = await pctLabel.textContent();
    expect(text).toContain('%');
  });

  test.skip('should configure teaser duration', async ({ page }) => {
    test.skip(true, 'Teaser duration not user-configurable');
  });

  test.skip('should show server-side teaser rendering option', async ({ page }) => {
    test.skip(true, 'Server-side rendering not implemented');
  });
});
