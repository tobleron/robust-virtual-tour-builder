import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');

async function uploadThreeScenes(page) {
  const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');

  // Upload Scene 1
  console.log('Uploading Scene 1...');
  await fileInput.setInputFiles([IMAGE_PATH_1]);
  const startBtn1 = page.getByRole('button', { name: 'Start Building' });
  await startBtn1.waitFor({ state: 'visible', timeout: 60000 });
  await startBtn1.click();
  // Use CSS classes for more robust matching across browsers
  console.log('Waiting for Scene 1 in list...');
  await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 120000 });

  // Upload Scene 2
  console.log('Uploading Scene 2...');
  await fileInput.setInputFiles([IMAGE_PATH_2]);
  const startBtn2 = page.getByRole('button', { name: 'Start Building' });
  await startBtn2.waitFor({ state: 'visible', timeout: 60000 });
  await startBtn2.click();
  console.log('Waiting for Scene 2 in list...');
  await expect(page.locator('.scene-item').nth(1)).toBeVisible({ timeout: 90000 });

  // Upload Scene 3
  console.log('Uploading Scene 3...');
  await fileInput.setInputFiles([IMAGE_PATH_3]);
  const startBtn3 = page.getByRole('button', { name: 'Start Building' });
  await startBtn3.waitFor({ state: 'visible', timeout: 60000 });
  await startBtn3.click();
  console.log('Waiting for Scene 3 in list...');
  await expect(page.locator('.scene-item').nth(2)).toBeVisible({ timeout: 90000 });

  console.log('All three scenes uploaded. Waiting for system unlock...');
  await expect(page.locator('.interaction-lock-overlay')).not.toBeVisible({ timeout: 60000 });
}

test.describe('FSM Interaction Logic', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await page.goto('/');
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
    page.on('console', msg => console.log(`BROWSER: ${msg.text()}`));

    test.setTimeout(300000);
    await uploadThreeScenes(page);
    // Wait for system to be unlocked
    console.log('Waiting for system to unlock...');
    await expect(page.locator('.interaction-lock-overlay')).not.toBeVisible({ timeout: 20000 });
    console.log('System unlocked.');

    // Rapidly click scenes
    console.log('Starting rapid clicking loop...');
    for (let i = 0; i < 10; i++) {
      // Click scenes 0, 1, 2 in cycle
      const sceneIndex = i % 3;
      console.log(`Click loop ${i}: scene ${sceneIndex}`);
      await page.locator(`.scene-item`).nth(sceneIndex).click();
      // Small delay to allow some processing but still be "rapid"
      await page.waitForTimeout(500);
    }

    // Since we clicked 10 times (i=0 to 9), and 9 % 3 = 0, last click was index 0
    console.log('Verifying final state...');
    await expect(page.locator('.scene-item').nth(0)).toHaveClass(/bg-slate-50\/50/, { timeout: 15000 });
    await expect(page.locator('#v-scene-persistent-label')).toBeHidden({ timeout: 15000 });
    console.log('Test completed successfully.');
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
