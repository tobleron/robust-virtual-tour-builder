import { test, expect } from '@playwright/test';
import path from 'path';

test('should upload image and view in panorama', async ({ page }) => {
  await page.goto('/');

  // Upload image
  // There are two file inputs, we want the one for images
  const fileInput = page.locator('input[type="file"][accept*="image"]');
  await fileInput.setInputFiles([
    'tests/fixtures/154407_002.webp',
    'tests/fixtures/154618_004.webp'
  ]);

  // Wait for processing (scene item appears)
  await page.waitForSelector('.scene-item', { timeout: 15000 });

  // Verify scene appears in sidebar
  const sceneItems = page.locator('.scene-item');
  await expect(sceneItems).toHaveCount(2);

  // Click to view first scene
  await sceneItems.first().click();

  // Verify panorama loads (canvas is present)
  // Pannellum (or similar) usually creates a canvas or specific container
  // ViewerUI.res mentions #viewer-hotspot-lines which is an SVG overlay
  // The actual viewer is likely rendered by a library into the root or a container.
  // We can check for the utility bar which only shows up when scenes are loaded
  await expect(page.locator('#viewer-utility-bar')).toBeVisible();
});
