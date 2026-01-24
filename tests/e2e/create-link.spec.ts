import { test, expect } from '@playwright/test';

test('should create hotspot link between scenes', async ({ page }) => {
  await page.goto('/');

  // Setup: Upload 2 scenes
  const fileInput = page.locator('input[type="file"][accept*="image"]');
  await fileInput.setInputFiles([
    'tests/fixtures/154407_002.webp',
    'tests/fixtures/154618_004.webp'
  ]);

  await page.waitForSelector('.scene-item', { timeout: 15000 });
  const scenes = page.locator('.scene-item');
  await expect(scenes).toHaveCount(2);

  // Select first scene
  await scenes.first().click();

  // Enable linking mode
  // First button in utility bar
  const addLinkBtn = page.locator('#viewer-utility-bar button').first();
  await addLinkBtn.click();

  // Verify notification or visual cue?
  // ViewerUI.res: EventBus.dispatch(ShowNotification("Link Mode: ACTIVE", #Success))
  // We can just proceed to click.

  // Click on panorama to create hotspot (center of screen)
  // Ensure we are clicking on the canvas/viewer area.
  await page.mouse.click(500, 400);

  // Wait for Modal
  // Modal title "Link Destination"
  await expect(page.getByText('Link Destination')).toBeVisible();

  // Select target scene
  const select = page.locator('#link-target');
  // Option values are scene names. Filenames are usually the default names.
  // 154618_004.webp -> likely "154618_004"
  // Let's check the second option value
  // We can just select by index or label.
  // The select has options.
  await select.selectOption({ index: 1 }); // Index 0 is "-- Select Room --", Index 1 is first scene (current), Index 2 is second scene?
  // Logic in LinkModal:
  // maps scenes. if i == activeIndex (current), returns null (no option).
  // So if we are on Scene 1, Scene 2 should be the only option (besides default).
  // So index 1 should be Scene 2.

  // Click Save
  await page.getByRole('button', { name: 'Save Link' }).click();

  // Verify sidebar link count
  // Scene item has a link icon and count if > 0
  // The structure is: div with LucideIcons.Link and span with count
  const linkCount = scenes.first().locator('.text-\\[9px\\]').getByText('1');
  await expect(linkCount).toBeVisible();
});
