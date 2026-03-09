import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import {
  createHotspotAtViewerCenter,
  resetClientState,
  selectFirstLinkTarget,
  uploadImageAndWaitForSceneCount,
  waitForBuilderShellReady,
  waitForNavigationStabilization,
} from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');

test.describe('Editor Interactions', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    // Jules hardening: Wait for viewer logic to stabilize after load
    await waitForBuilderShellReady(page);
    await page.waitForTimeout(1000);

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
  });

  test('should create a hotspot, link scenes, and verify visual pipeline', async ({ page }) => {
    test.setTimeout(240000);
    const sceneItems = page.locator('.scene-item');
    await expect(sceneItems).toHaveCount(2);

    // Stabilize and click
    await expect(sceneItems.first()).toBeVisible({ timeout: 15000 });
    await sceneItems.first().click();

    await page.waitForSelector('#panorama-a.active', { state: 'visible', timeout: 30000 });
    await waitForNavigationStabilization(page);

    // Jules hardening: ensure NavigationFSM is idle before interaction
    await page.waitForFunction(() => {
      // @ts-ignore
      const state = window.store.getState();
      return state?.navigationState?.navigationFsm === 'IdleFsm' || state?.navigationState?.navigationFsm?.TAG === 0;
    });
    await createHotspotAtViewerCenter(page);

    // Expect Modal
    await expect(page.getByText('Link Destination')).toBeVisible({ timeout: 15000 });

    // Verify System is in Linking Mode
    const isLinkingMode = await page.evaluate(() => {
      // @ts-ignore
      return window.store.getState().isLinking;
    });
    expect(isLinkingMode).toBe(true);

    await selectFirstLinkTarget(page);
    await page.getByRole('button', { name: 'Save Link' }).click();

    // Verify Modal Closed
    await expect(page.getByText('Link Destination')).toBeHidden({ timeout: 10000 });

    // Verify System exited Linking Mode
    const isLinkingModeEnded = await page.evaluate(() => {
      // @ts-ignore
      return window.store.getState().isLinking;
    });
    expect(isLinkingModeEnded).toBe(false);

    // Verify Visual Pipeline Update
    const pipelineWrapper = page.locator('.visual-pipeline-wrapper');
    await expect(pipelineWrapper).toBeVisible({ timeout: 10000 });

    const pipelineNode = page.locator('.pipeline-node').first();
    await expect(pipelineNode).toBeVisible({ timeout: 10000 });
  });

  test('should sync tour name property', async ({ page }) => {
    test.setTimeout(180000);
    const nameInput = page.locator('input.sidebar-project-input');
    await expect(nameInput).toBeVisible({ timeout: 15000 });
    await nameInput.fill('Renamed Tour');
    await nameInput.press('Enter');
    await expect(nameInput).toHaveValue('Renamed Tour', { timeout: 10000 });
  });
});
