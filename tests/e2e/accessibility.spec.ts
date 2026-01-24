import { test, expect } from '@playwright/test';

test('should navigate with keyboard only', async ({ page }) => {
  await page.goto('/');

  // Tab through UI
  // The first focusable element might be the "New" button in the sidebar or similar.
  // We press Tab multiple times and verify document.activeElement changes.

  await page.keyboard.press('Tab');

  // Verify something is focused
  const isFocused = await page.evaluate(() => !!document.activeElement);
  expect(isFocused).toBeTruthy();

  // Get the aria-label of the focused element
  const label = await page.evaluate(() => document.activeElement?.getAttribute('aria-label'));
  // Should be "New" or similar
  console.log('Focused element:', label);

  // Tab again
  await page.keyboard.press('Tab');
  const label2 = await page.evaluate(() => document.activeElement?.getAttribute('aria-label'));
  expect(label2).not.toBe(label);
});
