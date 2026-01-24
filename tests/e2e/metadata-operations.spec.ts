import { test, expect } from '@playwright/test';

test('should edit scene metadata', async ({ page }) => {
  await page.goto('/');

  // Upload 1 scene
  const fileInput = page.locator('input[type="file"][accept*="image"]');
  await fileInput.setInputFiles(['tests/fixtures/154407_002.webp']);
  await page.waitForSelector('.scene-item');

  // --- Category Change ---
  // Default is usually "outdoor" (Sun icon) or based on previous session.
  // The toggle button is in the utility bar (3rd button usually)
  // Let's find it by icon content or aria/tooltip if available.
  // ViewerUI.res: Tooltip content="Toggle Category"

  // Note: Tooltips in Radix UI often only appear on hover, but the button is there.
  // We can select by icon or order.
  const utilBar = page.locator('#viewer-utility-bar');
  // Finding button with "Sun" or "Home" icon
  const catBtn = utilBar.locator('button').nth(2);

  await catBtn.click();
  // Verify notification
  await expect(page.getByText('Category: INDOOR')).toBeVisible(); // or OUTDOOR depending on toggle

  // --- Floor Level Change ---
  // Floor nav is at bottom left
  const floorNav = page.locator('#viewer-floor-nav');
  // Click "First Floor" (+1)
  await floorNav.getByRole('button', { name: '+1' }).click();

  // Verify notification
  await expect(page.getByText('Floor: First Floor')).toBeVisible();
});
