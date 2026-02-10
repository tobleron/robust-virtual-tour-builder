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

async function handleUpload(page, imagePath, expectedSceneIndex) {
  const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
  await fileInput.setInputFiles([imagePath]);

  // "Start Building" should appear in the Upload Summary modal
  const startBtn = page.getByRole('button', { name: /Start Building/i });
  try {
    // Increased timeout due to slow backend processing in test environment
    await startBtn.waitFor({ state: 'visible', timeout: 90000 });
    await startBtn.click();
  } catch (e) {
    console.log(`Start Building button skipped for scene ${expectedSceneIndex} (not visible)`);
    // If button didn't appear, maybe the scene appeared directly?
  }

  await expect(page.locator('.scene-item').nth(expectedSceneIndex)).toBeVisible({ timeout: 90000 });
}

test.describe('Full Workflow: Upload -> Link -> Export', () => {
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

  test('should complete full tour creation workflow', async ({ page }) => {
    test.setTimeout(300000); // 5 minutes

    console.log('Step 1: Uploading images...');
    await handleUpload(page, IMAGE_PATH_1, 0);
    await handleUpload(page, IMAGE_PATH_2, 1);
    await handleUpload(page, IMAGE_PATH_3, 2);

    console.log('Scenes created:', await page.locator('.scene-item').count());

    // 2. Link Scenes (Scene 1 -> Scene 2)
    console.log('Step 2: Linking scenes...');
    await page.locator('.scene-item').nth(0).click();
    await page.waitForTimeout(1000);

    const viewer = page.locator('#viewer-stage');
    const box = await viewer.boundingBox();
    if (!box) throw new Error('Viewer not found');

    await page.keyboard.down('Alt');
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await page.keyboard.up('Alt');

    await expect(page.getByText('Link Destination')).toBeVisible();

    // Select index 1 (first valid scene, index 0 is placeholder "-- Select Room --")
    await page.selectOption('#link-target', { index: 1 });
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden();

    // 3. Export Project
    console.log('Step 3: Exporting project...');
    const exportBtn = page.getByLabel('Export Tour');
    await expect(exportBtn).toBeVisible();

    const downloadPromise = page.waitForEvent('download', { timeout: 60000 });
    await exportBtn.click();

    const download = await downloadPromise;
    const downloadPath = await download.path();
    console.log(`Downloaded to: ${downloadPath}`);

    expect(download.suggestedFilename()).toContain('.zip');
    expect(await download.failure()).toBeNull();
  });
});
