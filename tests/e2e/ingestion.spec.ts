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
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload(); // Reload to ensure app starts from clean state
  });

  test('should upload a .vt.zip and load the project', async ({ page }) => {
    const fileInput = page.locator('input[type="file"][accept=".vt.zip,.zip"]');
    await fileInput.setInputFiles(ZIP_PATH);

    // Handle Upload Summary modal
    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await startBtn.waitFor({ state: 'visible', timeout: 30000 });
    await startBtn.click();

    // Verify scene appears in the list - use a more robust check for the text containing '# Scene 1' or similar if it's the HUD
    // but here it's the .scene-item in sidebar
    await expect(page.locator('.scene-item').filter({ hasText: 'Scene 1' }).first()).toBeVisible({ timeout: 30000 });
    await expect(page.locator('input.sidebar-project-input')).toHaveValue('Test Tour', { timeout: 10000 });
  });

  test('should upload images and create new scenes', async ({ page }) => {
    const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
    await fileInput.setInputFiles([IMAGE_PATH]);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await startBtn.waitFor({ state: 'visible', timeout: 30000 });
    await startBtn.click();

    await expect(page.locator('.scene-item').filter({ hasText: 'image' }).first()).toBeVisible({ timeout: 30000 });
  });
});
