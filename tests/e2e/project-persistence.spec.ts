import { test, expect } from '@playwright/test';

test('should save and load project', async ({ page }) => {
  await page.goto('/');

  // Setup: Upload scenes
  const imageInput = page.locator('input[type="file"][accept*="image"]');
  await imageInput.setInputFiles([
    'tests/fixtures/154407_002.webp',
    'tests/fixtures/154618_004.webp'
  ]);

  await page.waitForSelector('.scene-item', { timeout: 15000 });
  await expect(page.locator('.scene-item')).toHaveCount(2);

  // Set a Project Name to verify it persists
  const nameInput = page.locator('#project-name-input');
  await nameInput.fill('Test Project Persistence');

  // Save project
  const downloadPromise = page.waitForEvent('download');
  const saveBtn = page.locator('button[aria-label="Save"]');
  await saveBtn.click();
  const download = await downloadPromise;

  // Wait for save notification
  await expect(page.getByText('Project saved')).toBeVisible();

  const downloadPath = await download.path();
  expect(downloadPath).toBeTruthy();

  // Reload page to clear state
  await page.reload();

  // Verify state is cleared (no scenes)
  // Sidebar logic: "No scenes" message
  await expect(page.getByText('No scenes')).toBeVisible();

  // Load project
  const projectInput = page.locator('input[type="file"][accept*=".zip"]');
  await projectInput.setInputFiles(downloadPath as string);

  // Wait for load notification
  await expect(page.getByText('Project loaded')).toBeVisible();

  // Verify scenes restored
  await expect(page.locator('.scene-item')).toHaveCount(2);

  // Verify Project Name restored
  await expect(nameInput).toHaveValue('Test Project Persistence');
});
