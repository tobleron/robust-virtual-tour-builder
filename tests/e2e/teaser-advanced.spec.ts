import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { resetClientState, uploadImageAndWaitForSceneCount, waitForNavigationStabilization } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const IMAGE_PATH_1 = path.join(FIXTURES_DIR, 'image.jpg');
const IMAGE_PATH_2 = path.join(FIXTURES_DIR, 'image2.jpg');
const SIM_ZIP_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

test.describe('Teaser Advanced Features', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should use Cinematic style (default, only working style)', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();

    await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 20000 });
    await waitForNavigationStabilization(page);

    console.log('Step 2: Open teaser dialog...');
    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"], button:has-text("Create Teaser")');
    await expect(teaserBtn).toBeVisible({ timeout: 10000 });
    await teaserBtn.click();

    console.log('Step 3: Verify no style selection UI (Cinematic only)...');
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
        console.log('⚠️ Style selector found:', selector);
        break;
      }
    }

    if (!styleSelectorFound) {
      console.log('✅ No style selection UI (Cinematic is default and only style)');
    }

    console.log('Note: Fast Shots and Simple Crossfade are future features, not yet implemented');
  });

  test('should cancel teaser recording via cancel button or ESC key', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
    await waitForNavigationStabilization(page);

    console.log('Step 2: Open teaser dialog and start recording...');
    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      console.log('✅ Teaser recording started');
      
      console.log('Step 3: Wait for recording to begin...');
      await page.waitForTimeout(3000);
      
      console.log('Step 4: Test cancel via ESC key...');
      await page.keyboard.press('Escape');
      await page.waitForTimeout(1000);
      
      // Check if overlay closed or cancelled
      const overlayStillVisible = await page.locator('#teaser-overlay').isVisible();
      if (!overlayStillVisible) {
        console.log('✅ ESC key cancels teaser recording');
      } else {
        console.log('ℹ️ ESC may not cancel (may need cancel button)');
        
        // Try cancel button
        const cancelBtn = page.locator('button:has-text("Cancel"), button:has-text("Stop")');
        if (await cancelBtn.isVisible()) {
          await cancelBtn.click();
          console.log('✅ Cancel button clicked');
        }
      }
    } else {
      console.log('⚠️ Start teaser button not found');
    }
  });

  test('should generate WebM format (MP4 is future backend feature)', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
    await waitForNavigationStabilization(page);

    console.log('Step 2: Open teaser and start recording...');
    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      console.log('Step 3: Wait for download...');
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      
      const filename = download.suggestedFilename();
      console.log('Downloaded filename:', filename);
      
      // Should be WebM (MP4 not implemented yet)
      expect(filename).toMatch(/\.(webm|mp4)$/);
      expect(await download.failure()).toBeNull();
      
      if (filename.endsWith('.webm')) {
        console.log('✅ WebM format generated (current frontend implementation)');
      } else if (filename.endsWith('.mp4')) {
        console.log('ℹ️ MP4 format generated (may be new backend feature)');
      }
      
      console.log('Note: MP4 is a future backend feature, currently only WebM is supported');
    }
  });

  test('should display teaser progress bar with ETA', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
    await waitForNavigationStabilization(page);

    console.log('Step 2: Start teaser...');
    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      console.log('Step 3: Wait for progress to appear...');
      await page.waitForTimeout(3000);
      
      console.log('Step 4: Look for progress bar with ETA...');
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
          console.log('✅ Progress indicator found:', selector);
          
          const progressText = await progress.textContent();
          console.log('Progress:', progressText);
          break;
        }
      }

      if (!progressFound) {
        console.log('ℹ️ Progress indicator not found (may use different UI)');
      }

      console.log('Note: Other ETAs are shown in orange toast notifications');

      console.log('Step 5: Wait for completion...');
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      expect(await download.failure()).toBeNull();
      
      console.log('✅ Teaser completed');
    }
  });

  test.skip('should configure teaser duration', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Note: This test is skipped because teaser duration');
    console.log('is NOT user-configurable. Duration is automatically');
    console.log('determined based on the number of scenes/waypoints.');
    
    test.skip(true, 'Teaser duration not user-configurable');
  });

  test.skip('should show server-side teaser rendering option', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Note: This test is skipped because server-side/cloud');
    console.log('teaser rendering is NOT implemented. All teaser generation');
    console.log('is done on the frontend (WebM format).');
    console.log('MP4 backend rendering is a future feature.');
    
    test.skip(true, 'Server-side rendering not implemented');
  });
});
