import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { uploadImageAndWaitForSceneCount } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');

test.describe('Visual Regression: Aesthetic Integrity', () => {
    test.beforeEach(async ({ page }) => {
        await setupAIObservability(page);
        
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
            }
        ];

        // Mock project import (ZIP)
        await page.route('**/api/project/import', async (route) => {
          await route.fulfill({
            status: 200,
            contentType: 'application/json',
            body: JSON.stringify({
              sessionId: 'visual-import-session',
              projectData: {
                tourName: 'Visual Test Tour',
                scenes,
              },
            }),
          });
        });

        // Mock single file upload / create
        await page.route('**/api/project/create', async (route) => {
             await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({
                  sessionId: 'visual-create-session',
                  projectData: {
                    tourName: 'Visual Test Tour',
                    scenes,
                  },
                }),
              });
        });
        await page.route('**/api/project/upload', async (route) => {
             await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({
                  sessionId: 'visual-upload-session',
                  projectData: {
                    tourName: 'Visual Test Tour',
                    scenes,
                  },
                }),
              });
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

        // Mock image file requests to prevent load errors
        await page.route('**/api/project/*/file/*', async (route) => {
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
        await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1, 30000);

        // 2. Wait for UI to stabilize (animations, images loaded)
        await expect(page.locator('.scene-item')).toBeVisible({ timeout: 15000 });
        await expect(page.locator('#panorama-a')).toBeVisible({ timeout: 30000 });
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
        await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1, 30000);
        
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
