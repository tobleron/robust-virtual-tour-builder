import { test, expect } from '@playwright/test';

test('should navigate via hotspots', async ({ page }) => {
  await page.goto('/');

  // Upload 2 scenes
  const fileInput = page.locator('input[type="file"][accept*="image"]');
  await fileInput.setInputFiles([
    'tests/fixtures/154407_002.webp',
    'tests/fixtures/154618_004.webp'
  ]);
  await page.waitForSelector('.scene-item');

  // Verify Scene 1 is active (index 0)
  const scenes = page.locator('.scene-item');
  await expect(scenes.first()).toHaveClass(/border-slate-200/); // Active class check (approximate)

  // Create link from Scene 1 to Scene 2
  await page.locator('#viewer-utility-bar button').first().click();
  await page.mouse.click(500, 400); // Center-ish

  // Select Scene 2 (Target)
  // Scene 2 name is likely "154618_004"
  await page.locator('#link-target').selectOption({ label: '154618_004' });
  await page.getByRole('button', { name: 'Save Link' }).click();

  // Exit Link Mode (it exits automatically on save)

  // Click the hotspot
  // The hotspot is an element with class .pnlm-hotspot
  // Pannellum renders them.
  await page.waitForSelector('.pnlm-hotspot');
  await page.locator('.pnlm-hotspot').first().click();

  // Verify Scene 2 is now active
  // Scene 2 item should have the active styling
  await expect(scenes.nth(1)).toHaveClass(/border-slate-200/);

  // Scene 1 should NOT be active
  await expect(scenes.first()).not.toHaveClass(/border-slate-200/);
});
