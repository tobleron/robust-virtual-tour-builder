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

test.describe('Editor Interactions', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
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

    // Wait for scene item and viewer lock release
    await expect(page.locator('.scene-item').filter({ hasText: 'image' }).first()).toBeVisible({ timeout: 30000 });
    // Ensure TransitionLock has released the viewer for interaction
    await page.waitForFunction(() => {
      // @ts-ignore
      return window.store && window.store.state && window.store.state.transitionLock === 'Idle';
    }, { timeout: 30000 }).catch(() => console.log("Warning: TransitionLock check timed out, proceeding anyway..."));


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

  test('should create a hotspot, link scenes, and verify visual pipeline', async ({ page }) => {
    test.setTimeout(90000);
    // Use first scene
    await page.waitForSelector('.scene-item', { timeout: 30000 });
    await page.locator('.scene-item').filter({ hasText: 'image' }).first().click();

    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });
    // Wait for viewer logic to stabilize (TransitionLock)
    await page.waitForTimeout(2000);

    const viewer = page.locator('#viewer-stage');
    const box = await viewer.boundingBox();
    if (!box) throw new Error('Viewer not found');

    // Create Hotspot (Alt + Click)
    const activePanorama = page.locator('#panorama-a.active');
    await activePanorama.click({
      position: { x: box.width / 2, y: box.height / 2 },
      modifiers: ['Alt']
    });

    // Expect Modal
    await expect(page.getByText('Link Destination')).toBeVisible({ timeout: 15000 });

    // Verify System is in Linking Mode (Yellow Dashed Lines visible)
    const isLinkingMode = await page.evaluate(() => {
      // @ts-ignore
      return window.store.state.ui.isLinking;
    });
    expect(isLinkingMode).toBe(true);

    await page.selectOption('#link-target', 'image2'); // Select by filename/ID match
    await page.getByRole('button', { name: 'Save Link' }).click();

    // Verify Modal Closed
    await expect(page.getByText('Link Destination')).toBeHidden({ timeout: 10000 });

    // Verify System exited Linking Mode (Yellow Lines removed, Red Lines persist)
    const isLinkingModeEnded = await page.evaluate(() => {
      // @ts-ignore
      return window.store.state.ui.isLinking;
    });
    expect(isLinkingModeEnded).toBe(false);

    // Verify Visual Pipeline Update
    // The visual pipeline should now show a connection or node
    const pipelineWrapper = page.locator('.visual-pipeline-wrapper');
    await expect(pipelineWrapper).toBeVisible({ timeout: 10000 });

    // Check for the pipeline node corresponding to the link
    const pipelineNode = page.locator('.pipeline-node');
    await expect(pipelineNode).toBeVisible({ timeout: 10000 });

    // Verify tooltip
    await pipelineNode.hover();
    await expect(page.locator('.node-tooltip')).toBeVisible();
    await expect(page.locator('.tooltip-text')).toContainText('image'); // Should contain scene name
  });

  test('should sync tour name property', async ({ page }) => {
    const nameInput = page.locator('input.sidebar-project-input');
    await expect(nameInput).toBeVisible({ timeout: 15000 });
    await nameInput.fill('Renamed Tour');
    await nameInput.press('Enter');
    await expect(nameInput).toHaveValue('Renamed Tour', { timeout: 10000 });
  });
});
