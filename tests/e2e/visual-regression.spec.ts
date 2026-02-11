import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');

test.describe('Visual Regression: Aesthetic Integrity', () => {
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

    test('Sidebar and HUD components should match aesthetic baselines', async ({ page }) => {
        // 1. Setup: Upload an image to populate the Sidebar and Viewer HUD
        const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
        await fileInput.setInputFiles([IMAGE_PATH_1]);

        const startBtn = page.getByRole('button', { name: 'Start Building' });
        await startBtn.waitFor({ state: 'visible', timeout: 30000 });
        await startBtn.click();

        // 2. Wait for UI to stabilize (animations, images loaded)
        await expect(page.locator('.scene-item')).toBeVisible({ timeout: 15000 });
        await expect(page.locator('#panorama-a.active')).toBeVisible({ timeout: 30000 });
        // Small delay to ensure blur/glassmorphism effects and transitions are settled
        await page.waitForTimeout(2000);

        // 3. Visual Assertions
        // Verification of the Sidebar (Layout, Buttons, Branding)
        const sidebar = page.locator('.sidebar-container');
        await expect(sidebar).toHaveScreenshot('sidebar-aesthetic.png', {
            maxDiffPixelRatio: 0.05, // Slight tolerance for font antialiasing differences
            mask: [page.locator('.sidebar-processing-percent')] // Mask progress text as it might fluctuate
        });

        // Verification of the Utility Bar (Floating Glassmorphism UI)
        const utilityBar = page.locator('#viewer-utility-bar');
        await expect(utilityBar).toHaveScreenshot('utility-bar-aesthetic.png');

        // Verification of the Floor Navigation
        const floorNav = page.locator('#viewer-floor-nav');
        await expect(floorNav).toHaveScreenshot('floor-navigation-aesthetic.png');

        // Verification of the Persistent Label (HUD Overlay)
        const sceneLabel = page.locator('#v-scene-persistent-label');
        await expect(sceneLabel).toHaveScreenshot('scene-label-aesthetic.png');
    });

    test('Modals and Popovers should maintain premium styling', async ({ page }) => {
        // Setup scene
        const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
        await fileInput.setInputFiles([IMAGE_PATH_1]);
        await page.getByRole('button', { name: 'Start Building' }).click();
        await expect(page.locator('.scene-item')).toBeVisible();

        // 1. Trigger Link Modal (Alt + Click in center of viewer)
        const viewer = page.locator('#viewer-stage');
        const box = await viewer.boundingBox();
        if (!box) throw new Error('Viewer not found');

        await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2, { modifiers: ['Alt'] });

        const modal = page.locator('div[role="dialog"]');
        await expect(modal).toBeVisible();
        await page.waitForTimeout(500); // Animation settling

        // 2. Visual Assertion: Modal Layout & Design
        await expect(modal).toHaveScreenshot('link-modal-aesthetic.png');
    });
});
