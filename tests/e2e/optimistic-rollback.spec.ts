import { test, expect } from '@playwright/test';
import path from 'path';
import { setupAIObservability } from './ai-helper';

test.describe('Optimistic Update Rollback', () => {
  const desktopPath = path.resolve('./tests/e2e/fixtures/tour.vt.zip');

  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    
    // Mock project import
    await page.route('**/api/project/import', async (route) => {
      const scenes = [
        {
          id: 'scene-0',
          name: 'Scene 0',
          file: 'images/image.jpg',
          hotspots: [],
          category: 'outdoor',
          floor: 'ground',
          label: 'Scene 0',
          isAutoForward: false,
        },
        {
          id: 'scene-1',
          name: 'Scene 1',
          file: 'images/image.jpg',
          hotspots: [],
          category: 'outdoor',
          floor: 'ground',
          label: 'Scene 1',
          isAutoForward: false,
        }
      ];

      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          sessionId: 'optimistic-import-session',
          projectData: {
            tourName: 'Optimistic Test Tour',
            scenes,
          },
        }),
      });
    });

    // Mock image file requests to prevent load errors
    await page.route('**/api/project/*/file/*', async (route) => {
      // Return a 1x1 pixel transparent gif or just 200 OK
      await route.fulfill({
        status: 200,
        contentType: 'image/jpeg',
        body: Buffer.from('ffd8ffe000104a46494600010101004800480000ffdb004300ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffdb004301ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc00011080001000103012200021101031101ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc400b5100002010303020403050504040000017d01020300041105122131410613516107227114328191a1082342b1c11552d1f02433627282090a161718191a25262728292a3435363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aaf0f1f2f3f4f5f6f7f8f9faffc4001f0100030101010101010101010000000000000102030405060708090a0bffc400b51100020102040403040705040400010277000102031104052131061241510761711322328108144291a1b1c109233352f0156272d10a162434e125f11718191a262728292a35363738393a434445464748494a535455565758595a636465666768696a737475767778797a838485868788898a92939495969798999aa2a3a4a5a6a7a8a9aaf0f1f2f3f4f5f6f7f8f9faffda000c03010002110311003f00bf00', 'hex')
      });
    });

    // Mock health check
    await page.route('**/health*', async (route) => {
      await route.fulfill({ status: 200, body: 'OK' });
    });

    // Mock media processing
    await page.route('**/api/media/process-full', async (route) => {
         await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({
              success: true,
              metadata: { width: 1000, height: 500 }
            }),
          });
    });

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
    // Wait for scenes to be loaded
    await expect(sceneItems.first()).toBeVisible({ timeout: 10000 });
    const initialCount = await sceneItems.count();
    expect(initialCount).toBeGreaterThan(0);

    // 2. Open context menu and delete
    await sceneItems.first().locator('button[aria-label^="Actions for"]').click();
    await page.getByText('Remove Scene').click();

    // Confirm deletion in modal
    const confirmBtn = page.getByRole('button', { name: /Delete|Confirm|Remove|Yes/i });
    if (await confirmBtn.isVisible()) {
        await confirmBtn.click();
    } else {
        // Try finding by text if role not matched or specific class
        await page.getByText(/Delete|Confirm/i).click();
    }

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

      // Wait for scenes
      await expect(page.locator('.scene-item').first()).toBeVisible();

      // 2. Add Hotspot (using "Add Link" button or similar interaction)
      const addLinkBtn = page.locator('button:has(.lucide-link-2)');
      
      // Ensure we are in a scene
      await page.waitForTimeout(1000);

      if (await addLinkBtn.isVisible()) {
          await addLinkBtn.click();
      } else {
           // Fallback to double click if button not found, though previous run suggests it might have worked?
           // Actually previous run failed 19 tests, but logs said hotspot addition passed?
           // Ah, I might have misread the logs or the pass was from a retry?
           // The summary said 3 passed. 5.1, 5.2, and 5.3 (no 5.3 passed).
           // Actually summary: "3 passed". 5.1, 5.2 passed. Hotspot passed?
           // Let's assume addLinkBtn works or we need to handle it.
           
           // If button not found, try context menu or double click
           const viewer = page.locator('#viewer-stage');
           const box = await viewer.boundingBox();
           if (box) {
               await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2, { modifiers: ['Alt'] });
           }
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
