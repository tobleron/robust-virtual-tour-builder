import { test, expect, Page } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { resetClientState, uploadImageAndWaitForSceneCount, waitForNavigationStabilization } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

async function startWithTwoScenes(page: Page) {
  await setupAIObservability(page);
  await resetClientState(page);
  await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
  await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
  await waitForNavigationStabilization(page);
  await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
  await waitForNavigationStabilization(page);
}

async function openLinkModalAt(page: Page, x = 430, y = 290) {
  const viewer = page.locator('#viewer-stage');
  await expect(viewer).toBeVisible({ timeout: 30000 });
  await page.keyboard.down('Alt');
  await viewer.click({ position: { x, y } });
  await page.keyboard.up('Alt');
  await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 10000 });
}

async function createSingleLink(page: Page) {
  await openLinkModalAt(page);
  await page.selectOption('#link-target', { index: 1 });
  await page.getByRole('button', { name: /Save Link|Save/i }).click();
  await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
}

test.describe('ESC Key Universal Cancel', () => {
  test.beforeEach(async ({ page }) => {
    await startWithTwoScenes(page);
  });

  test('ESC cancels linking mode', async ({ page }) => {
    const addLinkBtn = page.getByRole('button', { name: /Add Link/i });
    await addLinkBtn.click();
    await expect(page.getByText(/Link Mode/i)).toBeVisible({ timeout: 5000 });

    await page.keyboard.press('Escape');
    await expect(page.getByText(/Link Cancelled/i)).toBeVisible({ timeout: 5000 });
  });

  test('ESC cancels hotspot move', async ({ page }) => {
    await createSingleLink(page);
    const hotspot = page.locator('[id^="hs-react-"]').first();
    await hotspot.hover();
    await hotspot.locator('[title="Move Hotspot"]').click();
    await expect(page.getByText('Move Mode Active')).toBeVisible({ timeout: 5000 });

    await page.keyboard.press('Escape');
    await expect(page.getByText('Move Cancelled')).toBeVisible({ timeout: 5000 });
  });

  test('ESC closes link modal', async ({ page }) => {
    await openLinkModalAt(page);
    await page.keyboard.press('Escape');
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
  });

  test('ESC cancels active export flow', async ({ page }) => {
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]').first();
    await exportBtn.click();

    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")').first();
    await expect(startExportBtn).toBeVisible({ timeout: 10000 });
    await startExportBtn.click();

    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await expect(page.getByText(/cancelled|canceled/i)).toBeVisible({ timeout: 5000 });
  });

  test('ESC stops simulation', async ({ page }) => {
    const previewBtn = page.getByRole('button', { name: /Tour Preview/i });
    await previewBtn.click();
    await page.waitForTimeout(600);
    await page.keyboard.press('Escape');

    await expect(page.getByRole('button', { name: /Tour Preview/i })).toBeVisible({ timeout: 5000 });
  });
});
