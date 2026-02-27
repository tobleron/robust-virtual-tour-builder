import { test, expect, Page } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import {
  resetClientState,
  uploadImageAndWaitForSceneCount,
  waitForNavigationStabilization,
} from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

async function createLinkAtCenter(page: Page) {
  const viewer = page.locator('#viewer-stage');
  await expect(viewer).toBeVisible({ timeout: 30000 });
  await page.keyboard.down('Alt');
  await viewer.click({ position: { x: 460, y: 300 } });
  await page.keyboard.up('Alt');
  await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
  await page.selectOption('#link-target', { index: 1 });
  await page.getByRole('button', { name: /Save Link|Save/i }).click();
  await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 15000 });
}

async function openSceneActions(page: Page, sceneIndex: number) {
  const item = page.locator('.scene-item').nth(sceneIndex);
  await item.locator('button[aria-label^="Actions for"]').click();
}

test.describe('Scene Delete Undo', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);
    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
    await expect(page.locator('.scene-item')).toHaveCount(2);
  });

  test('delete scene and undo via notification button', async ({ page }) => {
    await openSceneActions(page, 1);
    await page.getByText('Remove Scene').click();

    await expect(page.locator('.scene-item')).toHaveCount(1, { timeout: 10000 });
    await expect(page.getByText('Scene deleted. Press U to undo.')).toBeVisible({ timeout: 5000 });

    await page.getByRole('button', { name: /Undo/i }).first().click();
    await expect(page.locator('.scene-item')).toHaveCount(2, { timeout: 10000 });
    await expect(page.getByText('Scene deletion undone')).toBeVisible({ timeout: 5000 });
  });

  test('delete scene and undo via keyboard U', async ({ page }) => {
    await openSceneActions(page, 1);
    await page.getByText('Remove Scene').click();

    await expect(page.locator('.scene-item')).toHaveCount(1, { timeout: 10000 });
    await expect(page.getByText('Scene deleted. Press U to undo.')).toBeVisible({ timeout: 5000 });

    await page.keyboard.press('u');
    await expect(page.locator('.scene-item')).toHaveCount(2, { timeout: 10000 });
    await expect(page.getByText('Scene deletion undone')).toBeVisible({ timeout: 5000 });
  });

  test('delete scene without undo times out and persists deletion', async ({ page }) => {
    let saveCallCount = 0;
    await page.route('**/api/project/save/**', async route => {
      saveCallCount += 1;
      await route.fulfill({ status: 200, body: '{}' });
    });

    await openSceneActions(page, 1);
    await page.getByText('Remove Scene').click();
    await expect(page.locator('.scene-item')).toHaveCount(1, { timeout: 10000 });

    await page.waitForTimeout(10000);
    await expect(page.getByText('Scene deleted. Press U to undo.')).toBeHidden({ timeout: 5000 });
    await expect(page.locator('.scene-item')).toHaveCount(1);
    expect(saveCallCount).toBeGreaterThanOrEqual(1);
  });

  test('clear links and undo restores hotspots', async ({ page }) => {
    await page.locator('.scene-item').first().click();
    await waitForNavigationStabilization(page);
    await createLinkAtCenter(page);

    await expect(page.locator('[id^="hs-react-"]')).toHaveCount(1, { timeout: 10000 });

    await openSceneActions(page, 0);
    await page.getByText('Clear Links').click();
    await expect(page.getByText('Links cleared. Press U to undo.')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('[id^="hs-react-"]')).toHaveCount(0, { timeout: 10000 });

    await page.getByRole('button', { name: /Undo/i }).first().click();
    await expect(page.getByText('Hotspots restored')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('[id^="hs-react-"]')).toHaveCount(1, { timeout: 10000 });
  });
});
