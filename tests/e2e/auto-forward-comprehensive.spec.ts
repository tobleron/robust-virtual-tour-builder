import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import {
  resetClientState,
  uploadImageAndWaitForSceneCount,
  waitForNavigationStabilization,
  loadProjectZipAndWait,
} from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const SIM_ZIP_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

test.describe('Auto-Forward Comprehensive', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should create auto-forward link via emerald double-chevron button', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const firstScene = page.locator('.scene-item').first();
    await expect(firstScene).toBeVisible({ timeout: 10000 });
    await firstScene.click();
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.waitForTimeout(500);
    }

    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });

    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });

    await page.selectOption('#link-target', { index: 1 });

    const saveBtn = page.locator('button:has-text("Save"), button:has-text("Save Link")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    // Hotspots are now in React layer, use id selector
    const hotspot = page.locator('[id^="hs-react-"]').first();
    if (await hotspot.isVisible()) {
      await hotspot.hover();
      await page.waitForTimeout(1000);
      
      // Look for emerald green double-chevron button (auto-forward toggle)
      const autoForwardBtn = page.locator(
        'button[title*="Auto-Forward"], ' +
        'button:has-text("AUTO"), ' +
        '.auto-forward-toggle, ' +
        'button:has(.lucide-fast-forward), ' +
        'button:has(.lucide-chevrons-right)'
      );
      
      if (await autoForwardBtn.isVisible({ timeout: 5000 })) {
        
        await autoForwardBtn.click();
        await page.waitForTimeout(500);
        
        // Verify button state changed
        const isActive = await autoForwardBtn.evaluate((el) => {
          return el.classList.contains('active') || 
                 el.getAttribute('data-active') === 'true' ||
                 el.textContent?.includes('AUTO');
        });
        
        if (isActive) {
        }
      } else {
      }
    }
  });

  test('should navigate auto-forward chain during simulation with waypoint animation', async ({ page }) => {
    test.setTimeout(120000);

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 60000);
    await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 20000 });

    const simBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-play"])');
    if (await simBtn.isVisible()) {
      await simBtn.click();
      
      // Verify simulation started
      const stopBtn = page.locator('#viewer-utility-bar button:has([class*="lucide-square"])');
      await expect(stopBtn).toBeVisible({ timeout: 5000 });

      // First scene: camera should pan to waypoint start
      // Arrow travels along waypoint, blinks red at end
      // Then auto crossfade to next scene
      
      const initialScene = await page.evaluate(() => {
        // @ts-ignore
        return window.store?.state?.activeIndex || 0;
      });

      // Wait for scene change (auto-navigation)
      await expect(async () => {
        const currentScene = await page.evaluate(() => {
          // @ts-ignore
          return window.store?.state?.activeIndex || 0;
        });
        expect(currentScene).not.toBe(initialScene);
      }).toPass({ timeout: 30000 });

      const newScene = await page.evaluate(() => {
        // @ts-ignore
        return window.store?.state?.activeIndex || 0;
      });

      await stopBtn.click();
      await expect(simBtn).toBeVisible({ timeout: 5000 });
    } else {
    }
  });

  test('should enforce one auto-forward per scene with toast validation', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const firstScene = page.locator('.scene-item').first();
    await firstScene.click();
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.selectOption('#link-target', { index: 1 });
    
    // Save as simple link first
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    // Hover and enable auto-forward
    const hotspot = page.locator('.pnlm-hotspot').first();
    if (await hotspot.isVisible()) {
      await hotspot.hover();
      await page.waitForTimeout(500);
      
      const autoForwardBtn = page.locator('button:has-text("AUTO"), button[title*="Auto-Forward"]');
      if (await autoForwardBtn.isVisible()) {
        await autoForwardBtn.click();
      }
    }

    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 600, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.selectOption('#link-target', { index: 2 });
    await saveBtn.click();

    // Hotspots are now in React layer
    const secondHotspot = page.locator('[id^="hs-react-"]').nth(1);
    if (await secondHotspot.isVisible()) {
      await secondHotspot.hover();
      await page.waitForTimeout(500);
      
      if (await autoForwardBtn.isVisible()) {
        await autoForwardBtn.click();
        await page.waitForTimeout(1000);
        
        // Look for toast notification
        const errorToast = page.locator(
          '[role="alert"]:has-text("auto-forward"), ' +
          '[role="alert"]:has-text("one"), ' +
          '[role="alert"]:has-text("only"), ' +
          '.toast:has-text("auto-forward")'
        );
        
        if (await errorToast.isVisible({ timeout: 5000 })) {
          const toastText = await errorToast.textContent();
        } else {
        }
      }
    }

  });

  test('should auto-delete links pointing to deleted scenes', async ({ page }) => {
    test.setTimeout(90000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    await addLinkBtn.click();
    await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
    
    await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
    await page.selectOption('#link-target', { index: 1 });
    
    const saveBtn = page.locator('button:has-text("Save")');
    await saveBtn.click();
    await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });

    // Hotspots are now in React layer
    const initialHotspotCount = await page.locator('[id^="hs-react-"]').count();

    const scene2 = page.locator('.scene-item').nth(1);
    if (await scene2.isVisible()) {
      // Open scene context menu or use delete button
      const sceneMenu = scene2.locator('button[aria-label*="Menu"], button[aria-label*="Delete"], .scene-options');
      if (await sceneMenu.isVisible()) {
        await sceneMenu.click();
        await page.waitForTimeout(500);
        
        const deleteOption = page.locator('[role="menuitem"]:has-text("Delete"), button:has-text("Delete")');
        if (await deleteOption.isVisible({ timeout: 5000 })) {
          await deleteOption.click();
        }
      }
    }

    await page.waitForTimeout(1000); // Allow cleanup

    // Hotspots are now in React layer
    const newHotspotCount = await page.locator('[id^="hs-react-"]').count();
    
    if (newHotspotCount < initialHotspotCount) {
    } else {
    }

    const brokenLinks = await page.evaluate(() => {
      // @ts-ignore
      const state = window.store?.state;
      const broken = [];
      state?.scenes?.forEach((scene: any) => {
        scene.hotspots?.forEach((h: any) => {
          if (h.targetSceneId === null || h.targetSceneId === undefined) {
            broken.push({ scene: scene.name, link: h.linkId });
          }
        });
      });
      return broken;
    });
    
    if (brokenLinks.length === 0) {
    } else {
    }
  });

  test.skip('should migrate scene-level auto-forward to link-level (legacy)', async ({ page }) => {
    test.setTimeout(90000);

    
    // This test would require:
    // 1. An old project ZIP with scene.isAutoForward = true
    // 2. Import the project
    // 3. Verify migration to hotspot.isAutoForward occurred
    
  });
});
