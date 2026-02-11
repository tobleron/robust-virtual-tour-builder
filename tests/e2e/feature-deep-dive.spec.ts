import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');

async function setupThreeScenes(page) {
    const fileInput = page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');

    // Upload 3 images
    await fileInput.setInputFiles([IMAGE_PATH_1]);
    await page.getByRole('button', { name: 'Start Building' }).click();
    await expect(page.locator('.scene-item')).toHaveCount(1, { timeout: 30000 });

    await fileInput.setInputFiles([IMAGE_PATH_2]);
    await page.getByRole('button', { name: 'Start Building' }).click();
    await expect(page.locator('.scene-item')).toHaveCount(2, { timeout: 30000 });

    await fileInput.setInputFiles([IMAGE_PATH_3]);
    await page.getByRole('button', { name: 'Start Building' }).click();
    await expect(page.locator('.scene-item')).toHaveCount(3, { timeout: 30000 });

    // Link Scene 1 -> Scene 2
    await page.locator('.scene-item').nth(0).click();
    await page.waitForSelector('#panorama-a.active', { state: 'visible' });
    const box = await page.locator('#viewer-stage').boundingBox();
    await page.mouse.click(box!.x + box!.width / 2, box!.y + box!.height / 2, { modifiers: ['Alt'] });
    await page.selectOption('#link-target', { index: 1 }); // Scene 2
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden();

    // Link Scene 2 -> Scene 3
    await page.locator('.scene-item').nth(1).click();
    await page.waitForTimeout(1000);
    await page.mouse.click(box!.x + box!.width / 2, box!.y + box!.height / 2, { modifiers: ['Alt'] });
    await page.selectOption('#link-target', { index: 2 }); // Scene 3
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden();
}

test.describe('Feature Deep Dive & Comprehensive Tests', () => {
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

    test('6.1: Visual Pipeline - Reordering via Drag and Drop', async ({ page }) => {
        test.setTimeout(120000);
        await setupThreeScenes(page);

        const nodes = page.locator('.pipeline-node');
        const initialCount = await nodes.count();
        expect(initialCount).toBe(2);

        // Get initial order (text content or ids)
        const initialNodes = await nodes.allTextContents();
        console.log('Initial Pipeline:', initialNodes);

        // Drag node 0 to drop zone after node 1
        // Drop zones are index 0, 1, 2
        const firstNode = nodes.nth(0);
        const lastDropZone = page.locator('.drop-zone').last();

        await firstNode.dragTo(lastDropZone);

        // Verify order changed
        await page.waitForTimeout(1000);
        const finalNodes = await nodes.allTextContents();
        console.log('Final Pipeline:', finalNodes);
        expect(finalNodes[0]).not.toBe(initialNodes[0]);
    });

    test('6.2: Visual Pipeline - Removal via Context Menu', async ({ page }) => {
        test.setTimeout(90000);
        await setupThreeScenes(page);

        const nodes = page.locator('.pipeline-node');
        expect(await nodes.count()).toBe(2);

        // Right click first node
        page.on('dialog', dialog => dialog.accept()); // Confirm removal
        await nodes.first().click({ button: 'right' });

        // Verify one node remains
        await expect(nodes).toHaveCount(1, { timeout: 10000 });
    });

    test('6.3: Metadata Sync - Rename & Label Propagation', async ({ page }) => {
        test.setTimeout(90000);
        await setupThreeScenes(page);

        // Rename first scene
        const sceneItem = page.locator('.scene-item').first();
        await sceneItem.click();

        const renameInput = page.locator('input.sidebar-scene-name-input').first();
        await renameInput.fill('Grand Entrance');
        await renameInput.press('Enter');

        // Verify label in Viewer HUD
        await expect(page.locator('#v-scene-persistent-label')).toHaveText('# Grand Entrance', { timeout: 10000 });

        // Verify tooltip in Visual Pipeline
        const pipelineNode = page.locator('.pipeline-node').first();
        await pipelineNode.hover();
        await expect(page.locator('.tooltip-text').first()).toHaveText('Grand Entrance');
    });

    test('6.4: Floor Navigation - Metadata Persistence', async ({ page }) => {
        test.setTimeout(90000);
        await setupThreeScenes(page);

        await page.locator('.scene-item').first().click();

        // Select Floor 1 (+1)
        const floorNav = page.locator('#viewer-floor-nav');
        const floorOneBtn = floorNav.getByRole('button', { name: '+1' });
        await floorOneBtn.click();

        // Verify notification
        await expect(page.locator('text=/Floor: First Floor/i')).toBeVisible();

        // Refresh and verify persistence
        await page.reload();
        await expect(page.locator('.scene-item').first()).toBeVisible();
        await page.locator('.scene-item').first().click();

        // Check if button is still active (active state has specific border/bg)
        await expect(floorOneBtn).toHaveClass(/bg-\[#ea580c\]/);
    });

    test('6.5: Accessibility - ESC Key Resilience', async ({ page }) => {
        await setupThreeScenes(page);

        // 1. Enter Linking Mode
        await page.locator('.scene-item').first().click();
        const addLinkBtn = page.getByRole('button', { name: /Add Link/i });
        await addLinkBtn.click();
        await expect(page.getByText('Link Mode: Choose Destination')).toBeVisible();

        // 2. Press ESC
        await page.keyboard.press('Escape');

        // 3. Verify Modal and Overlay are gone
        await expect(page.getByText('Link Mode: Choose Destination')).toBeHidden();
        await expect(page.locator('.interaction-lock-overlay')).not.toBeVisible();

        // Ensure "Add Link" button is enabled again
        await expect(addLinkBtn).toBeEnabled();
    });
});
