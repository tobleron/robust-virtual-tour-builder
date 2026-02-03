import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const ZIP_PATH = path.join(FIXTURES_DIR, 'tour.vt.zip');
const IMAGE_PATH = path.join(FIXTURES_DIR, 'image.jpg');

test.describe('Ingestion Pipeline', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => localStorage.clear());
  });

  test('should upload a .vt.zip and load the project', async ({ page }) => {
    const fileInput = page.locator('input[type="file"][accept=".vt.zip,.zip"]');
    await fileInput.setInputFiles(ZIP_PATH);

    // Handle Upload Summary modal
    try {
        const startBtn = page.getByRole('button', { name: 'Start Building' });
        await startBtn.waitFor({ state: 'visible', timeout: 5000 });
        await startBtn.click();
    } catch (e) {
        // Ignore
    }

    await expect(page.locator('.scene-item').filter({ hasText: 'Scene 1' }).first()).toBeVisible({ timeout: 20000 });
    await expect(page.locator('input.sidebar-project-input')).toHaveValue('Test Tour');
  });

  test('should upload images and create new scenes', async ({ page }) => {
    const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
    await fileInput.setInputFiles([IMAGE_PATH]);

    try {
        const startBtn = page.getByRole('button', { name: 'Start Building' });
        await startBtn.waitFor({ state: 'visible', timeout: 3000 });
        await startBtn.click();
    } catch (e) { }

    await expect(page.locator('.scene-item').filter({ hasText: 'image' }).first()).toBeVisible({ timeout: 20000 });
  });
});
