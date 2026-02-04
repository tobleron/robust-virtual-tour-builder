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
    await page.route('**/api/project/save/*', async route => {
      // Never fulfill, just hang to simulate interruption
      await new Promise(r => setTimeout(r, 10000));
    });

    // 2. Trigger save (e.g. by deleting a scene which triggers auto-save via optimistic action)
    const sceneItems = page.locator('.scene-item');
    expect(await sceneItems.count()).toBeGreaterThan(0);

    await sceneItems.first().locator('button[aria-label^="Actions for"]').click();
    await page.getByText('Remove Scene').click();

    // 3. Reload page immediately
    await page.reload();

    // 4. Expect recovery prompt
    await expect(page.getByText('Interrupted Operations')).toBeVisible({ timeout: 10000 });

    // 5. Dismiss
    await page.getByText('Dismiss All').click();
  });
});
