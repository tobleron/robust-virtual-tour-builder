import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability, setupAuthentication } from './ai-helper';
import { uploadImageAndWaitForSceneCount } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');

async function uploadThreeScenes(page) {
  await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1, 120000);
  await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2, 90000);
  await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_3, 3, 90000);
  await expect(page.locator('.interaction-lock-overlay')).not.toBeVisible({ timeout: 20000 });
}

test.describe('FSM Interaction Logic', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await setupAuthentication(page, 'dev-token');
    await page.goto('/builder');
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();
  });

  test('rapid scene clicking should not hang', async ({ page }) => {
    // Pipe browser console logs to stdout for debugging

    test.setTimeout(300000);
    await uploadThreeScenes(page);
    // Wait for system to be unlocked
    await expect(page.locator('.interaction-lock-overlay')).not.toBeVisible({ timeout: 20000 });

    // Rapidly click scenes
    for (let i = 0; i < 10; i++) {
      // Click scenes 0, 1, 2 in cycle
      const sceneIndex = i % 3;
      await page.locator(`.scene-item`).nth(sceneIndex).click();
      // Small delay to allow some processing but still be "rapid"
      await page.waitForTimeout(500);
    }

    // Since we clicked 10 times (i=0 to 9), and 9 % 3 = 0, last click was index 0
    await expect(page.locator('.scene-item').nth(0)).toHaveClass(/bg-slate-50\/50/, { timeout: 15000 });
    await expect(page.locator('#v-scene-persistent-label')).toBeHidden({ timeout: 15000 });
  });

  test('UI should not dim during scene preload', async ({ page }) => {
    test.setTimeout(180000);
    await uploadThreeScenes(page);

    await page.locator('.scene-item').nth(1).click();

    // Check that overlay does NOT appear during preload (Regression for fixed UI lock)
    await page.waitForTimeout(500);
    const overlay = page.locator('.interaction-lock-overlay');
    await expect(overlay).not.toBeVisible({ timeout: 2000 });
  });

  test('can interrupt scene loading by clicking another scene', async ({ page }) => {
    test.setTimeout(300000);
    await uploadThreeScenes(page);
    await expect(page.locator('.interaction-lock-overlay')).not.toBeVisible();

    // Start loading scene 1 (index 1)
    await page.locator('.scene-item').nth(1).click();

    // Immediately click scene 2 (index 2) (interrupt)
    // Wait for the first click to be processed (throttle is 200ms)
    await page.waitForTimeout(300);
    await page.locator('.scene-item').nth(2).click();

    // Should end up on scene 2
    await expect(page.locator('.scene-item').nth(2)).toHaveClass(/bg-slate-50\/50/, { timeout: 30000 });
    await expect(page.locator('#v-scene-persistent-label')).toBeHidden({ timeout: 30000 });
  });
});
