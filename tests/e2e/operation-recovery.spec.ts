import { test, expect } from '@playwright/test';
import path from 'path';

test.describe('Operation Recovery', () => {
  const desktopPath = path.resolve('./tests/e2e/fixtures/tour.vt.zip');

  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(desktopPath);
    const startBtn = page.getByRole('button', { name: /Start Building|Close/i });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
  });

  test('should show recovery prompt after interrupted save', async ({ page }) => {
    // 1. Mock slow save
    await page.route('**/api/project/save', async route => {
      // Never fulfill, just hang to simulate interruption (longer than the wait)
      await new Promise(r => setTimeout(r, 20000));
    });

    // 2. Trigger manual save (which uses the journal)
    const saveBtn = page.getByRole('button', { name: 'Save' });
    await expect(saveBtn).toBeVisible();
    await saveBtn.click();

    // Wait for the 2000ms debounce in SidebarActions to trigger the actual save
    await page.waitForTimeout(3000);

    // 3. Reload page immediately
    await page.reload();

    // 4. Expect recovery prompt
    await expect(page.getByText('Interrupted Operations Detected')).toBeVisible({ timeout: 15000 });

    // 5. Dismiss
    await page.getByRole('button', { name: 'Dismiss' }).click();

    // 6. Verify prompt is gone
    await expect(page.getByText('Interrupted Operations Detected')).toBeHidden();
  });
});
