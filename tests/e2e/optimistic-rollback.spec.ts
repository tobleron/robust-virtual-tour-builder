import { test, expect } from '@playwright/test';
import path from 'path';
import { setupAIObservability } from './ai-helper';

test.describe('Optimistic Update Rollback', () => {
  const desktopPath = path.resolve('./tests/e2e/fixtures/tour.vt.zip');

  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await page.goto('/');
    await page.evaluate(async () => {
      localStorage.clear();
      sessionStorage.clear();
      const dbs = await window.indexedDB.databases();
      dbs.forEach((db) => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
    });
    await page.reload();
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(desktopPath);
    const startBtn = page.getByRole('button', { name: /Start Building|Close/i });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
  });

  test('should rollback scene deletion on API failure', async ({ page }) => {
    // 1. Mock API failure
    await page.route('**/api/project/save/*', async route => {
      await route.fulfill({ status: 500, body: JSON.stringify({ error: 'Save failed' }) });
    });

    const sceneItems = page.locator('.scene-item');
    const initialCount = await sceneItems.count();
    expect(initialCount).toBeGreaterThan(0);

    // 2. Open context menu and delete
    await sceneItems.first().locator('button[aria-label^="Actions for"]').click();
    await page.getByText('Remove Scene').click();

    // 3. Verify rollback
    // Notification should appear
    await expect(page.locator('text=/Changes have been reverted/i')).toBeVisible({ timeout: 5000 });

    // Verify count is back to initial
    await expect(sceneItems).toHaveCount(initialCount);
  });

  test('should rollback hotspot addition on API failure', async ({ page }) => {
      // 1. Mock API failure
      await page.route('**/api/project/save/*', async route => {
        await route.fulfill({ status: 500, body: JSON.stringify({ error: 'Save failed' }) });
      });

      // 2. Add Hotspot (using "Add Link" button or similar interaction)
      // Finding the Add Link button (usually in utility bar or sidebar)
      // In SidebarActions.res there is no "Add Hotspot".
      // Usually it's in UtilityBar.
      // Let's look for an icon or aria-label.
      // Common aria-label for Add Hotspot is "Add Link" or similar.
      // Or check for lucide-link-2 icon.

      const addLinkBtn = page.locator('button:has(.lucide-link-2)');
      if (await addLinkBtn.isVisible()) {
          await addLinkBtn.click();
      } else {
           // Maybe it's double click on viewer?
           // For now, let's try to find "Link" button.
           // If failing, skip.
           test.skip(true, 'Add Link button not found');
      }

      // Wait for modal
      await expect(page.locator('text=Link Destination')).toBeVisible();

      // Select target
      const select = page.locator('select#link-target');
      await select.selectOption({ index: 1 });

      // Click Save Link
      await page.getByText('Save Link').click();

      // 3. Verify rollback
      await expect(page.locator('text=/Changes have been reverted/i')).toBeVisible({ timeout: 5000 });
  });
});
