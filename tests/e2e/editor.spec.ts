import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

test.describe('Editor Interactions', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');

    const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
    await fileInput.setInputFiles([IMAGE_PATH_1]);
    try {
        const startBtn = page.getByRole('button', { name: 'Start Building' });
        await startBtn.waitFor({ state: 'visible', timeout: 3000 });
        await startBtn.click();
    } catch (e) { }
    await expect(page.locator('.scene-item').filter({ hasText: 'image' }).first()).toBeVisible({ timeout: 20000 });

    await fileInput.setInputFiles([IMAGE_PATH_2]);
    try {
        const startBtn = page.getByRole('button', { name: 'Start Building' });
        await startBtn.waitFor({ state: 'visible', timeout: 3000 });
        await startBtn.click();
    } catch (e) { }
    await expect(page.locator('.scene-item').filter({ hasText: 'image2' }).first()).toBeVisible({ timeout: 20000 });
  });

  test('should create a hotspot and link scenes', async ({ page }) => {
    await page.locator('.scene-item').filter({ hasText: 'image' }).first().click();
    await page.waitForSelector('#panorama-a.active', { state: 'visible' });
    await page.waitForTimeout(1000);

    const viewer = page.locator('#viewer-stage');
    const box = await viewer.boundingBox();
    if (!box) throw new Error('Viewer not found');

    await page.keyboard.down('Alt');
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await page.keyboard.up('Alt');

    await expect(page.getByText('Link Destination')).toBeVisible();
    await page.selectOption('#link-target', 'image2');
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden();
  });

  test('should sync tour name property', async ({ page }) => {
    const nameInput = page.locator('input.sidebar-project-input');
    await nameInput.fill('Renamed Tour');
    await nameInput.press('Enter');
    await expect(nameInput).toHaveValue('Renamed Tour');
  });
});
