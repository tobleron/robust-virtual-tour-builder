import { test, expect } from '@playwright/test';
import path from 'path';
import os from 'os';
import { setupAIObservability } from './ai-helper';

/**
 * Robustness Suite: Each test targets a specific potential failure point
 * to ensure clear separation of concerns.
 */
test.describe('Application Robustness - Separation of Concerns', () => {
  
  const desktopPath = path.join(os.homedir(), 'Desktop', 'xyz.zip');

  test.beforeEach(async ({ page }) => {
    // Setup AI-focused diagnostic logging
    await setupAIObservability(page);

    await page.goto('/');
    // Every test starts with a clean import to be independent
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(desktopPath);
    const startBtn = page.getByRole('button', { name: /Start Building|Close/i });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
  });

  test('Area: State Machine - Concurrent Mode Transitions', async ({ page }) => {
    console.log('Testing: Simultaneous mode triggers...');
    const addLinkBtn = page.locator('button:has([class*="lucide-plus"])');
    const autoPilotBtn = page.locator('button:has([class*="lucide-play"])');
    
    // Attempt to trigger two modes at once
    await Promise.all([
      addLinkBtn.click().catch(() => {}),
      autoPilotBtn.click().catch(() => {})
    ]);

    // Expected: The app should prioritize one or handle both sequentially without crashing
    const errorBoundary = page.locator('text=/Something went wrong/i');
    await expect(errorBoundary).not.toBeVisible();
    await expect(page.locator('#viewer-stage')).toBeVisible();
  });

  test('Area: Navigation - Rapid Scene Switching', async ({ page }) => {
    console.log('Testing: Rapid navigation lifecycle...');
    const sceneItems = page.locator('.scene-list-item, [role="button"]:has-text("#")');
    const count = await sceneItems.count();
    
    if (count > 1) {
      // Rapidly switch scenes without waiting for previous load to finish
      for (let i = 0; i < Math.min(count, 5); i++) {
        await sceneItems.nth(i).click({ force: true });
      }
    }

    // Expected: Viewer should be in a valid state for the LAST clicked scene
    await expect(page.locator('#viewer-stage')).toBeVisible();
    await expect(page.locator('text=/Something went wrong/i')).not.toBeVisible();
  });

  test('Area: Persistence - Rapid Saving during Interaction', async ({ page }) => {
    console.log('Testing: Interaction during Save operations...');
    const saveBtn = page.getByLabel('Save');
    const sceneItems = page.locator('.scene-list-item, [role="button"]:has-text("#")');

    // Trigger a save and immediately navigate away
    await saveBtn.click();
    if (await sceneItems.count() > 1) {
      await sceneItems.last().click();
    }

    // Expected: UI remains responsive and save finishes (or fails gracefully)
    await expect(page.locator('#sidebar')).toBeVisible();
    await expect(page.locator('text=/Something went wrong/i')).not.toBeVisible();
  });

  test('Area: Input Handling - Keyboard/Mouse Interruptions', async ({ page }) => {
    console.log('Testing: Escape key during active UI transitions...');
    const addLinkBtn = page.locator('button:has([class*="lucide-plus"])');
    
    await addLinkBtn.click();
    // Hit Escape multiple times while the UI is responding
    await page.keyboard.press('Escape');
    await page.keyboard.press('Escape');

    // Expected: No deadlock; app returns to Idle state
    await expect(page.locator('button:has([class*="lucide-plus"])')).toBeEnabled();
    await expect(page.locator('text=/Something went wrong/i')).not.toBeVisible();
  });

});