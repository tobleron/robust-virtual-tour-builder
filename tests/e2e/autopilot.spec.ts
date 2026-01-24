import { test, expect } from '@playwright/test';

test('should run autopilot simulation', async ({ page }) => {
  await page.goto('/');

  // Setup: Upload scenes
  const fileInput = page.locator('input[type="file"][accept*="image"]');
  await fileInput.setInputFiles([
    'tests/fixtures/154407_002.webp',
    'tests/fixtures/154618_004.webp'
  ]);

  await page.waitForSelector('.scene-item', { timeout: 15000 });

  // Locate AutoPilot button (2nd in utility bar)
  const autoPilotBtn = page.locator('#viewer-utility-bar button').nth(1);

  // Hover to check tooltip "Start Auto-Pilot"
  await autoPilotBtn.hover();
  await expect(page.getByText('Start Auto-Pilot')).toBeVisible();

  // Start simulation
  await autoPilotBtn.click();

  // Wait for state change (button icon change or tooltip change)
  // Move mouse away and back to trigger tooltip update
  await page.mouse.move(0, 0);
  await page.waitForTimeout(500); // Wait for state update
  await autoPilotBtn.hover();

  // Verify tooltip is now "Stop Auto-Pilot"
  await expect(page.getByText('Stop Auto-Pilot')).toBeVisible();

  // Stop simulation
  await autoPilotBtn.click();

  await page.mouse.move(0, 0);
  await page.waitForTimeout(500);
  await autoPilotBtn.hover();

  // Verify tooltip is back to "Start Auto-Pilot"
  await expect(page.getByText('Start Auto-Pilot')).toBeVisible();
});
