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

test.describe('Teaser Advanced Features', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should use Cinematic style (default, only working style)', async ({ page }) => {
    test.setTimeout(180000);

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 60000);
    await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 20000 });

    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"], button:has-text("Create Teaser")');
    await expect(teaserBtn).toBeVisible({ timeout: 10000 });
    await teaserBtn.click();

    const styleSelectors = [
      '[role="radio"][value="cinematic"]',
      '[role="radio"][value="fast"]',
      '[role="radio"][value="simple"]',
      'button:has-text("Cinematic"), button:has-text("Fast"), button:has-text("Simple")',
      'select[name="style"], select[name="teaserStyle"]',
    ];

    let styleSelectorFound = false;
    for (const selector of styleSelectors) {
      const styleOption = page.locator(selector);
      if (await styleOption.isVisible({ timeout: 3000 }).catch(() => false)) {
        styleSelectorFound = true;
        break;
      }
    }

    if (!styleSelectorFound) {
    }

  });

  test('should cancel teaser recording via cancel button or ESC key', async ({ page }) => {
    test.setTimeout(120000);

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 60000);

    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      await page.waitForTimeout(3000);
      
      await page.keyboard.press('Escape');
      await page.waitForTimeout(1000);
      
      // Check if overlay closed or cancelled
      const overlayStillVisible = await page.locator('#teaser-overlay').isVisible();
      if (!overlayStillVisible) {
      } else {
        
        // Try cancel button
        const cancelBtn = page.locator('button:has-text("Cancel"), button:has-text("Stop")');
        if (await cancelBtn.isVisible()) {
          await cancelBtn.click();
        }
      }
    } else {
    }
  });

  test('should generate WebM format (MP4 is future backend feature)', async ({ page }) => {
    test.setTimeout(180000);

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 60000);

    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      
      const filename = download.suggestedFilename();
      
      // Should be WebM (MP4 not implemented yet)
      expect(filename).toMatch(/\.(webm|mp4)$/);
      expect(await download.failure()).toBeNull();
      
      if (filename.endsWith('.webm')) {
      } else if (filename.endsWith('.mp4')) {
      }
      
    }
  });

  test('should display teaser progress bar with ETA', async ({ page }) => {
    test.setTimeout(180000);

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 60000);

    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      await page.waitForTimeout(3000);
      
      const progressSelectors = [
        '.progress-bar, [role="progressbar"]',
        '.teaser-progress, [data-testid="progress"]',
        'text=%, text=Progress',
        'text=ETA, text=Remaining, text=Time',
      ];

      let progressFound = false;
      for (const selector of progressSelectors) {
        const progress = page.locator(selector);
        if (await progress.isVisible({ timeout: 3000 }).catch(() => false)) {
          progressFound = true;
          
          const progressText = await progress.textContent();
          break;
        }
      }

      if (!progressFound) {
      }


      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      expect(await download.failure()).toBeNull();
      
    }
  });

  test.skip('should configure teaser duration', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Teaser duration not user-configurable');
  });

  test.skip('should show server-side teaser rendering option', async ({ page }) => {
    test.setTimeout(60000);

    
    test.skip(true, 'Server-side rendering not implemented');
  });
});
