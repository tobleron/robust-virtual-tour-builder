import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { clickStartBuildingIfVisible, waitForSidebarInteractive } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH = path.join(FIXTURES_DIR, 'image.jpg');

test.describe('Error Recovery Scenarios', () => {
    test.beforeEach(async ({ page }) => {
        await setupAIObservability(page);
        await page.goto('/');


        await page.evaluate(async () => {
            localStorage.clear();
            sessionStorage.clear();
            const dbs = await window.indexedDB.databases();
            dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
        });
        await page.reload();
    });

    test('4.1: Network failure during upload should trigger retry', async ({ page }) => {
        test.setTimeout(120000);

        let failCount = 0;
        await page.route('**/api/media/process-full*', async route => {
            if (failCount < 1) {
                failCount++;
                await route.fulfill({ status: 500, body: 'Internal Server Error' });
            } else {
                await route.continue();
            }
        });

        const fileInput = page.locator('input[type="file"][accept*="image"]');
        await fileInput.setInputFiles(IMAGE_PATH);

        // Verify retry notification (using a regex that matches the notification text)
        await expect(page.locator('text=/Retrying/i')).toBeVisible({ timeout: 30000 });

        // Verify eventual success
        await clickStartBuildingIfVisible(page, 60000);
        await waitForSidebarInteractive(page, 60000);

        await expect(page.locator('.scene-item')).toBeVisible();
    });

    test('4.3: Invalid JSON in project file should handle gracefully', async ({ page }) => {
        const fileInput = page.locator('input[type="file"][accept*=".zip"]');

        // Using an image file as a dummy "zip" which will fail to parse as a project
        const dummyFile = path.join(FIXTURES_DIR, 'image.jpg');
        await fileInput.setInputFiles(dummyFile);

        // Verify error message
        await expect(page.locator('text=/Failed to load project/i')).toBeVisible({ timeout: 10000 });

        // App should not crash
        await expect(page.locator('#sidebar')).toBeVisible();
    });

    test('4.4: Browser refresh during save should trigger recovery modal', async ({ page }) => {
        test.setTimeout(120000);

        // 1. Create a project
        const fileInput = page.locator('input[type="file"][accept*="image"]');
        await fileInput.setInputFiles(IMAGE_PATH);
        await clickStartBuildingIfVisible(page, 30000);
        await waitForSidebarInteractive(page, 30000);

        // 2. Start save
        const saveBtn = page.getByLabel('Save');
        await expect(saveBtn).toBeVisible();

        // Mock save to be slow so we can refresh during it
        await page.route('**/api/project/save', async route => {
            await new Promise(r => setTimeout(r, 10000));
            await route.continue();
        });

        await saveBtn.click();

        // 3. Refresh mid-save
        await page.reload();

        // 4. Verify recovery modal
        await expect(page.locator('role=dialog')).toBeVisible({ timeout: 15000 });
        await expect(page.locator('text=/Interrupted Operations/i')).toBeVisible();

        // 5. Dismiss
        await page.locator('button:has-text("Dismiss All")').click();
        await expect(page.locator('text=/Interrupted Operations/i')).not.toBeVisible();
    });
});
