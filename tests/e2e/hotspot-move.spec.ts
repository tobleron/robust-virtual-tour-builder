import { test, expect, Page } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { resetClientState, uploadImageAndWaitForSceneCount, waitForBuilderShellReady, waitForNavigationStabilization } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

async function createLinkAt(page: Page, x: number, y: number) {
  const viewer = page.locator('#viewer-stage');
  await expect(viewer).toBeVisible({ timeout: 30000 });

  await page.keyboard.down('Alt');
  await viewer.click({ position: { x, y } });
  await page.keyboard.up('Alt');

  await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
  await page.selectOption('#link-target', { index: 1 });
  await page.getByRole('button', { name: /Save Link|Save/i }).click();
  await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 15000 });
}

async function firstHotspot(page: Page) {
  const hs = page.locator('[id^="hs-react-"]').first();
  await expect(hs).toBeVisible({ timeout: 15000 });
  return hs;
}

test.describe('Hotspot Move', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);
    await waitForBuilderShellReady(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
    await createLinkAt(page, 420, 280);
  });

  test('moves a hotspot to a new position', async ({ page }) => {
    const hotspot = await firstHotspot(page);
    const before = await hotspot.boundingBox();
    expect(before).not.toBeNull();

    await hotspot.hover();
    await hotspot.locator('[title="Move Hotspot"]').click();
    await expect(page.getByText('Move Mode Active')).toBeVisible({ timeout: 5000 });

    await page.locator('#viewer-stage').click({ position: { x: 650, y: 360 } });
    await page.waitForTimeout(1200);

    const after = await hotspot.boundingBox();
    expect(after).not.toBeNull();
    expect(Math.abs((after?.x ?? 0) - (before?.x ?? 0)) > 2 || Math.abs((after?.y ?? 0) - (before?.y ?? 0)) > 2).toBe(true);
  });

  test('cancels hotspot move via ESC', async ({ page }) => {
    const hotspot = await firstHotspot(page);
    const before = await hotspot.boundingBox();
    expect(before).not.toBeNull();

    await hotspot.hover();
    await hotspot.locator('[title="Move Hotspot"]').click();
    await expect(page.getByText('Move Mode Active')).toBeVisible({ timeout: 5000 });

    await page.keyboard.press('Escape');
    await expect(page.getByText('Move Cancelled')).toBeVisible({ timeout: 5000 });
    await page.waitForTimeout(400);

    const after = await hotspot.boundingBox();
    expect(after).not.toBeNull();
    expect(Math.abs((after?.x ?? 0) - (before?.x ?? 0))).toBeLessThanOrEqual(2);
    expect(Math.abs((after?.y ?? 0) - (before?.y ?? 0))).toBeLessThanOrEqual(2);
  });

  test('cancels hotspot move via center button', async ({ page }) => {
    const hotspot = await firstHotspot(page);
    const before = await hotspot.boundingBox();
    expect(before).not.toBeNull();

    await hotspot.hover();
    await hotspot.locator('[title="Move Hotspot"]').click();
    await expect(page.getByText('Move Mode Active')).toBeVisible({ timeout: 5000 });

    await hotspot.click();
    await page.waitForTimeout(400);

    const movingHotspot = await page.evaluate(() => (window as any).store?.state?.movingHotspot ?? null);
    expect(movingHotspot).toBeNull();

    const after = await hotspot.boundingBox();
    expect(after).not.toBeNull();
    expect(Math.abs((after?.x ?? 0) - (before?.x ?? 0))).toBeLessThanOrEqual(2);
    expect(Math.abs((after?.y ?? 0) - (before?.y ?? 0))).toBeLessThanOrEqual(2);
  });

  test('prevents switching to another hotspot while one move is active', async ({ page }) => {
    await createLinkAt(page, 520, 300);

    const hotspots = page.locator('[id^="hs-react-"]');
    await expect(hotspots).toHaveCount(2);

    const first = hotspots.nth(0);
    const second = hotspots.nth(1);

    await first.hover();
    await first.locator('[title="Move Hotspot"]').click();
    await expect(page.getByText('Move Mode Active')).toBeVisible({ timeout: 5000 });

    let moving = await page.evaluate(() => (window as any).store?.state?.movingHotspot ?? null);
    expect(moving).not.toBeNull();

    await second.hover();
    await second.locator('[title="Move Hotspot"]').click({ force: true });
    await page.waitForTimeout(300);

    const movingAfterSecondClick = await page.evaluate(() => (window as any).store?.state?.movingHotspot ?? null);
    expect(movingAfterSecondClick).toEqual(moving);
  });
});
