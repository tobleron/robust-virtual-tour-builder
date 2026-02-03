import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

test.describe('Editor Interactions', () => {
  test.beforeEach(async ({ page }) => {
    page.on('console', msg => console.log('BROWSER:', msg.text()));
    await page.goto('/');
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();

    const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
    await fileInput.setInputFiles([IMAGE_PATH_1]);
    const startBtn1 = page.getByRole('button', { name: 'Start Building' });
    try {
      await startBtn1.waitFor({ state: 'visible', timeout: 30000 });
      await startBtn1.click();
    } catch (e) {
      await page.screenshot({ path: 'editor_fail_startbtn1.png' });
      const html = await page.content();
      fs.writeFileSync('editor_fail.html', html);
      console.log('HTML Length:', html.length);
      throw e;
    }
    await expect(page.locator('.scene-item').filter({ hasText: 'image' }).first()).toBeVisible({ timeout: 30000 });

    await fileInput.setInputFiles([IMAGE_PATH_2]);
    const startBtn2 = page.getByRole('button', { name: 'Start Building' });
    try {
      await startBtn2.waitFor({ state: 'visible', timeout: 30000 });
      await startBtn2.click();
    } catch (e) {
      await page.screenshot({ path: 'editor_fail_startbtn2.png' });
      throw e;
    }
    await expect(page.locator('.scene-item').filter({ hasText: 'image' }).nth(1)).toBeVisible({ timeout: 30000 });
  });

  test('should create a hotspot and link scenes', async ({ page }) => {
    test.setTimeout(90000);
    // Use first scene
    await page.waitForSelector('.scene-item', { timeout: 30000 });
    await page.locator('.scene-item').filter({ hasText: 'image' }).first().click();

    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(2000); // Wait for viewer stabilization

    const viewer = page.locator('#viewer-stage');
    const box = await viewer.boundingBox();
    if (!box) throw new Error('Viewer not found');

    await page.keyboard.down('Alt');
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await page.keyboard.up('Alt');

    await expect(page.getByText('Link Destination')).toBeVisible({ timeout: 15000 });
    await page.selectOption('#link-target', 'image2');
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden({ timeout: 10000 });
  });

  test('should sync tour name property', async ({ page }) => {
    const nameInput = page.locator('input.sidebar-project-input');
    await expect(nameInput).toBeVisible({ timeout: 15000 });
    await nameInput.fill('Renamed Tour');
    await nameInput.press('Enter');
    await expect(nameInput).toHaveValue('Renamed Tour', { timeout: 10000 });
  });
});
