import { test, expect } from '@playwright/test';

test('should verify production features availability', async ({ page }) => {
  await page.goto('/');

  // Initial state: Buttons disabled or hidden?
  // Sidebar buttons: Export, Teaser.
  const exportBtn = page.getByRole('button', { name: 'Export' });
  const teaserBtn = page.getByRole('button', { name: 'Teaser' });

  // Before upload, they should be disabled or interactively blocked
  // Sidebar.res: disabled={!exportReady} (exportReady = totalHotspots > 0 ?? No, totalHotspots > 0)
  // Wait, let's check Sidebar.res logic:
  // let totalHotspots = ...
  // let exportReady = totalHotspots > 0
  // So Export is disabled until we have at least one link!

  // Teaser ready = totalHotspots >= 3 ?? No, totalHotspots >= 3

  await expect(exportBtn).toBeDisabled();
  await expect(teaserBtn).toBeDisabled();

  // Upload 3 scenes
  const fileInput = page.locator('input[type="file"][accept*="image"]');
  await fileInput.setInputFiles([
    'tests/fixtures/154407_002.webp',
    'tests/fixtures/154618_004.webp',
    'tests/fixtures/154744_005.webp'
  ]);
  await page.waitForSelector('.scene-item');

  // Still disabled because no hotspots created yet
  await expect(exportBtn).toBeDisabled();

  // Create a link to enable Export
  await page.locator('.scene-item').first().click();
  await page.locator('#viewer-utility-bar button').first().click(); // Add Link
  await page.mouse.click(500, 400);
  await page.locator('#link-target').selectOption({ index: 1 });
  await page.getByRole('button', { name: 'Save Link' }).click();

  // Now Export should be enabled
  await expect(exportBtn).toBeEnabled();

  // Teaser requires 3 hotspots?
  // Sidebar.res: let teaserReady = totalHotspots >= 3
  // We have 1 hotspot. Need 2 more.

  // Add 2nd hotspot
  await page.locator('#viewer-utility-bar button').first().click();
  await page.mouse.click(600, 400);
  await page.locator('#link-target').selectOption({ index: 1 });
  await page.getByRole('button', { name: 'Save Link' }).click();

  // Add 3rd hotspot
  await page.locator('#viewer-utility-bar button').first().click();
  await page.mouse.click(700, 400);
  await page.locator('#link-target').selectOption({ index: 1 });
  await page.getByRole('button', { name: 'Save Link' }).click();

  // Now Teaser should be enabled
  await expect(teaserBtn).toBeEnabled();

  // Click Export - Check for processing state
  await exportBtn.click();
  await expect(page.getByText('Exporting...')).toBeVisible();
});
