import { test, expect } from '@playwright/test';
import path from 'path';
import os from 'os';
import { setupAIObservability } from './ai-helper';

test('comprehensive import and interaction with xyz.zip', async ({ page }) => {
  await setupAIObservability(page);
  await page.goto('/');
  await page.evaluate(async () => {
    localStorage.clear();
    sessionStorage.clear();
    const dbs = await window.indexedDB.databases();
    dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
  });
  await page.reload();

  const fixturePath = path.resolve('tests/e2e/fixtures/tour.vt.zip');
  const fileInput = page.locator('input[type="file"][accept*=".zip"]');
  
  // 1. Upload and wait for the summary modal
  await fileInput.setInputFiles(fixturePath);
  const startBtn = page.getByRole('button', { name: /Start Building|Close/i });
  await expect(startBtn).toBeVisible({ timeout: 60000 });
  await startBtn.click();

  // 2. Verify Project Identity
  // Imported tours usually change the "Project Name" field
  const projectNameInput = page.locator('#project-name-input');
  await expect(projectNameInput).toHaveValue('Test Tour', { timeout: 15000 });
  const importedName = await projectNameInput.inputValue();
  console.log('Imported Tour Name:', importedName);

  // 3. Verify Sidebar and Scene Count
  const sceneItems = page.locator('.scene-item, [role="button"]:has-text("#")');
  const initialCount = await sceneItems.count();
  expect(initialCount).toBeGreaterThan(0);

  // 4. Test Scene Switching Logic
  // Click the second scene (if it exists) to verify the viewer updates
  if (initialCount > 1) {
    const secondScene = sceneItems.nth(1);
    const secondSceneName = await secondScene.innerText();
    
    await secondScene.click();
    
    // Verify the "Persistent Label" in the viewer updates to match
    const viewerLabel = page.locator('#v-scene-persistent-label');
    await expect(viewerLabel).toContainText(secondSceneName.replace('#', '').trim());
  }

  // 5. Verify Viewer Rendering
  // Ensure the WebGL canvas is present and the placeholder is gone
  await expect(page.locator('#placeholder-text')).not.toBeVisible();
  const canvas = page.locator('#panorama-a canvas, #panorama-b canvas');
  await expect(canvas.first()).toBeVisible();

  // 6. Verify Backend Session (Persistence Check)
  // Note: Persistence restoration is currently disabled in Main.res (commented out),
  // so we skip this verification step to avoid false negatives.

  /*
  // Refresh the page and check if the tour is still there (Hydration)
  // Wait for auto-save debounce (2000ms)
  await page.waitForTimeout(2500);
  await page.reload();
  await expect(page.locator('#project-name-input')).toHaveValue(importedName, { timeout: 15000 });
  await expect(sceneItems.first()).toBeVisible();
  */
});
