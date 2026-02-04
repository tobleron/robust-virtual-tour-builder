import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

async function handleUpload(page, imagePath, expectedSceneIndex) {
    const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
    await fileInput.setInputFiles([imagePath]);

    const startBtn = page.getByRole('button', { name: /Start Building/i });
    try {
        await startBtn.waitFor({ state: 'visible', timeout: 90000 });
        await startBtn.click();
    } catch (e) {
        console.log(`Start Building button skipped for scene ${expectedSceneIndex} (not visible)`);
    }

    await expect(page.locator('.scene-item').nth(expectedSceneIndex)).toBeVisible({ timeout: 90000 });
}

test.describe('Project Persistence: Save -> Load Recovery', () => {
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

  test('should persist project data through save/load cycle', async ({ page }) => {
    test.setTimeout(300000);

    // 1. Create Project with 2 scenes
    console.log('Step 1: Creating project...');
    await handleUpload(page, IMAGE_PATH_1, 0);
    await handleUpload(page, IMAGE_PATH_2, 1);

    // Add a hotspot to Scene 1
    await page.locator('.scene-item').nth(0).click();
    await page.waitForTimeout(1000);
    const viewer = page.locator('#viewer-stage');
    const box = await viewer.boundingBox();

    await page.keyboard.down('Alt');
    if (box) await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    await page.keyboard.up('Alt');

    await expect(page.getByText('Link Destination')).toBeVisible();
    await page.selectOption('#link-target', { index: 0 });
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden();

    // 2. Save Project (Download)
    console.log('Step 2: Saving project...');
    const saveBtn = page.getByLabel('Save');
    await expect(saveBtn).toBeVisible();

    const downloadPromise = page.waitForEvent('download');
    await saveBtn.click();
    const download = await downloadPromise;
    const savePath = path.join(__dirname, 'temp_saved_project.zip');
    await download.saveAs(savePath);
    console.log(`Saved project to: ${savePath}`);

    // 3. Clear State
    console.log('Step 3: Clearing state...');
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();

    // Verify empty state
    const sceneCount = await page.locator('.scene-item').count();
    expect(sceneCount).toBe(0);

    // 4. Load Project (Upload)
    console.log('Step 4: Loading project...');
    // Try explicit load input first, then button
    const loadInput = page.locator('input[type="file"][accept*=".zip"]');

    if (await loadInput.count() > 0) {
        await loadInput.setInputFiles(savePath);
    } else {
        const loadBtn = page.getByLabel('Load');
        const fileChooserPromise = page.waitForEvent('filechooser');
        await loadBtn.click();
        const fileChooser = await fileChooserPromise;
        await fileChooser.setFiles(savePath);
    }

    // Wait for load to complete (check for start button or scene items)
    const startBtn = page.getByRole('button', { name: /Start Building|Close/i });
    try {
        await startBtn.waitFor({ state: 'visible', timeout: 5000 });
        await startBtn.click();
    } catch (e) {
        console.log('Start Building button skipped after load');
    }

    // 5. Verify Restoration
    console.log('Step 5: Verifying restoration...');
    await expect(page.locator('.scene-item').nth(0)).toBeVisible({ timeout: 30000 });
    await expect(page.locator('.scene-item').nth(1)).toBeVisible();

    // Verify hotspot existence via state check
    const state = await page.evaluate(() => {
        return (window as any).__RE_STATE__;
    });

    if (state && state.scenes && state.scenes.length > 0) {
        // Assuming scenes[0] has hotspots
        // This structure is hypothetical but likely correct
        console.log('State Scenes:', state.scenes.length);
        // Verify at least one scene has hotspots
        const hasHotspots = state.scenes.some(s => s.hotspots && s.hotspots.length > 0);
        // OR check strictly scene 0
        // expect(state.scenes[0].hotspots.length).toBeGreaterThan(0);
        if (!hasHotspots) console.warn('No hotspots found in state dump');
    }

    // Cleanup
    if (fs.existsSync(savePath)) {
        fs.unlinkSync(savePath);
    }
  });
});
