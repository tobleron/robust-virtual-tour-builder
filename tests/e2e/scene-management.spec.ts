import { test, expect } from '@playwright/test';

test('should manage scenes: delete and reorder', async ({ page }) => {
  await page.goto('/');

  // Setup: Upload 3 scenes
  const fileInput = page.locator('input[type="file"][accept*="image"]');
  await fileInput.setInputFiles([
    'tests/fixtures/154407_002.webp',
    'tests/fixtures/154618_004.webp',
    'tests/fixtures/154744_005.webp'
  ]);

  await page.waitForSelector('.scene-item', { timeout: 20000 });
  const scenes = page.locator('.scene-item');
  await expect(scenes).toHaveCount(3);

  // --- Deletion ---
  // Click "More Actions" on the 3rd scene
  const lastScene = scenes.nth(2);
  await lastScene.hover();
  const menuBtn = lastScene.locator('button[aria-label^="Actions for"]');
  await menuBtn.click();

  // Click "Remove Scene" in dropdown
  await page.getByText('Remove Scene').click();

  // Verify count decreases
  await expect(scenes).toHaveCount(2);

  // --- Reordering ---
  // Drag first scene to second position
  const firstScene = scenes.first();
  const secondScene = scenes.nth(1);

  // Get initial names/IDs to verify swap
  const name1 = await firstScene.locator('h4').textContent();
  const name2 = await secondScene.locator('h4').textContent();

  // Perform drag
  await firstScene.dragTo(secondScene);

  // Verify order changed
  // This might be tricky depending on how React renders updates vs DOM stability
  // But the names should swap positions in the list
  await expect(scenes.first().locator('h4')).toHaveText(name2 as string);
  await expect(scenes.nth(1).locator('h4')).toHaveText(name1 as string);
});
