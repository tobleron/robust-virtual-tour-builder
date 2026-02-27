import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import JSZip from 'jszip';
import { setupAIObservability } from './ai-helper';
import {
  createHotspotAtViewerCenter,
  resetClientState,
  selectFirstLinkTarget,
  uploadImageAndWaitForSceneCount,
  waitForNavigationStabilization,
} from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');

test.describe('Full Workflow: Upload -> Link -> Export', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);
  });

  test('should complete full tour creation workflow', async ({ page }) => {
    test.setTimeout(300000); // 5 minutes

    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_3, 3);
    await waitForNavigationStabilization(page);


    // 2. Link Scenes (Scene 1 -> Scene 2)
    await page.locator('.scene-item').nth(0).click();
    await waitForNavigationStabilization(page);
    await createHotspotAtViewerCenter(page);

    await expect(page.getByText('Link Destination')).toBeVisible();

    await selectFirstLinkTarget(page);
    await page.getByRole('button', { name: 'Save Link' }).click();
    await expect(page.getByText('Link Destination')).toBeHidden();

    // 3. Export Project
    const exportBtn = page.getByLabel('Export Tour');
    await expect(exportBtn).toBeVisible();

    const processingStatus = page.locator('[role="status"]');
    const downloadPromise = page.waitForEvent('download', { timeout: 60000 });
    await exportBtn.click();
    await expect(processingStatus).toContainText(/Export/i, { timeout: 15000 });

    const download = await downloadPromise;
    const downloadPath = await download.path();

    expect(download.suggestedFilename()).toContain('.zip');
    expect(await download.failure()).toBeNull();

    if (!downloadPath || !fs.existsSync(downloadPath)) {
      throw new Error('Download path missing for export package');
    }

    const zipBytes = fs.readFileSync(downloadPath);
    const zip = await JSZip.loadAsync(zipBytes);
    const hdTemplate = zip.file('standalone/tour_hd/index.html');
    expect(hdTemplate).toBeTruthy();

    const hdHtml = await hdTemplate!.async('string');
    expect(hdHtml).toContain('class="looking-mode-indicator"');
    expect(hdHtml).toContain('id="viewer-floor-tags-export"');
    expect(hdHtml).toContain('FLOOR_TAG_SHORTCUT_PAGE_SIZE = 3');
    expect(hdHtml).toContain('<span class="mode-shortcut-key">L</span> to toggle');
    expect(hdHtml).toContain('.looking-mode-indicator');
    expect(hdHtml).toContain('background: rgba(0, 20, 60, 0.45)');
  });
});
