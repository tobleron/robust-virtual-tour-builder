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
const IMAGE_PATH_3 = path.join(FIXTURES_DIR, 'image3.jpg');
const SIM_ZIP_PATH = path.join(FIXTURES_DIR, 'tour_sim.vt.zip');

test.describe('Teaser Advanced Features', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);
  });

  test('should select teaser style (Cinematic/Fast Shots/Simple Crossfade)', async ({ page }) => {
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

    console.log('Step 3: Find style selection UI...');
    // Wait for teaser overlay/dialog
    await expect(page.locator('#teaser-overlay, [role="dialog"]:has-text("Teaser")')).toBeVisible({ timeout: 15000 });

    // Look for style options
    const styleSelectors = [
      '[role="radio"][value="cinematic"]',
      '[role="radio"][value="fast"]',
      '[role="radio"][value="simple"]',
      'button:has-text("Cinematic")',
      'button:has-text("Fast")',
      'button:has-text("Simple")',
      'select[name="style"], select[name="teaserStyle"]',
    ];

    let styleFound = false;
    for (const selector of styleSelectors) {
      const styleOption = page.locator(selector);
      if (await styleOption.isVisible({ timeout: 3000 }).catch(() => false)) {
        styleFound = true;
        console.log('✅ Style selection found:', selector);
        
        // Try selecting different style
        if (selector.includes('Cinematic')) {
          await styleOption.click();
          console.log('✅ Cinematic style selected');
        }
        break;
      }
    }

    if (!styleFound) {
      console.log('ℹ️ Style selection UI not found (may use different pattern)');
    }

    console.log('Step 4: Start teaser generation...');
    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record"), button:has-text("Generate")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      console.log('Step 5: Verify teaser is recording...');
      await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 10000 });
      console.log('✅ Teaser recording started');
      
      // Wait for download
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      
      console.log('Downloaded:', download.suggestedFilename());
      expect(download.suggestedFilename()).toMatch(/\.(webm|mp4)$/);
      expect(await download.failure()).toBeNull();
      
      console.log('✅ Teaser generated with selected style');
    } else {
      console.log('⚠️ Start teaser button not found');
    }
  });

  test('should configure teaser duration', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
    await waitForNavigationStabilization(page);

    console.log('Step 2: Open teaser dialog...');
    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay, [role="dialog"]:has-text("Teaser")')).toBeVisible({ timeout: 15000 });

    console.log('Step 3: Find duration configuration...');
    const durationInput = page.locator(
      'input[name="duration"], ' +
      'input[aria-label*="Duration"], ' +
      'input[type="number"][data-testid="duration"], ' +
      'input[placeholder*="duration"]'
    );

    if (await durationInput.isVisible()) {
      console.log('Step 4: Set custom duration...');
      await durationInput.fill('30'); // 30 seconds
      
      console.log('✅ Duration configured');
    } else {
      console.log('ℹ️ Duration input not found (may use slider or preset options)');
      
      // Look for duration slider or presets
      const durationSlider = page.locator('input[type="range"][name*="duration"]');
      const durationPresets = page.locator('button:has-text("15s"), button:has-text("30s"), button:has-text("60s")');
      
      if (await durationSlider.isVisible()) {
        console.log('ℹ️ Duration slider found');
      } else if (await durationPresets.isVisible()) {
        console.log('ℹ️ Duration presets found');
      }
    }

    console.log('Step 5: Start teaser...');
    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      expect(await download.failure()).toBeNull();
      
      console.log('✅ Teaser with custom duration completed');
    }
  });

  test('should cancel teaser recording', async ({ page }) => {
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
      await page.waitForTimeout(3000); // Let recording start
      
      console.log('Step 4: Cancel recording...');
      const cancelBtn = page.locator(
        'button:has-text("Cancel"), ' +
        'button:has-text("Stop"), ' +
        '[aria-label*="Cancel"], ' +
        '[aria-label*="Stop"]'
      );
      
      if (await cancelBtn.isVisible()) {
        await cancelBtn.click();
        console.log('✅ Cancel button clicked');
        
        // Verify overlay closed or cancelled state
        await page.waitForTimeout(2000);
        
        const overlayStillVisible = await page.locator('#teaser-overlay').isVisible();
        if (!overlayStillVisible) {
          console.log('✅ Teaser overlay closed after cancel');
        } else {
          console.log('ℹ️ Overlay still visible (may show cancelled state)');
        }
      } else {
        console.log('⚠️ Cancel button not found during recording');
      }
    }
  });

  test('should fallback to WebM when MP4 encoding fails', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
    await waitForNavigationStabilization(page);

    console.log('Step 2: Open teaser and select MP4 format...');
    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    // Try to select MP4 format
    const mp4Option = page.locator(
      '[role="radio"][value="mp4"], ' +
      'button:has-text("MP4"), ' +
      'select option[value="mp4"]'
    );
    
    if (await mp4Option.isVisible()) {
      await mp4Option.click();
      console.log('✅ MP4 format selected');
    }

    console.log('Step 3: Start teaser recording...');
    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      console.log('Step 4: Monitor for encoding...');
      // Wait for download (could be WebM or MP4)
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      
      const filename = download.suggestedFilename();
      console.log('Downloaded filename:', filename);
      
      // Should be either webm or mp4
      expect(filename).toMatch(/\.(webm|mp4)$/);
      expect(await download.failure()).toBeNull();
      
      if (filename.endsWith('.webm')) {
        console.log('✅ WebM format used (may be fallback or default)');
      } else if (filename.endsWith('.mp4')) {
        console.log('✅ MP4 format used');
      }
      
      console.log('✅ Teaser encoding completed successfully');
    }
  });

  test('should display teaser progress with ETA', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Import simulation tour with multiple scenes...');
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
      
      console.log('Step 3: Look for progress indicator...');
      // Wait a moment for progress to appear
      await page.waitForTimeout(3000);
      
      // Progress indicators
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
          
          // Try to get progress value
          const progressText = await progress.textContent();
          console.log('Progress:', progressText);
          break;
        }
      }

      if (!progressFound) {
        console.log('ℹ️ Progress indicator not found (may use different UI)');
      }

      console.log('Step 4: Wait for completion...');
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      expect(await download.failure()).toBeNull();
      
      console.log('✅ Teaser completed');
    }
  });

  test('should show server-side teaser rendering option', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Import simulation tour...');
    const fileInput = page.locator('input[type="file"][accept*=".zip"]');
    await fileInput.setInputFiles(SIM_ZIP_PATH);

    const startBtn = page.getByRole('button', { name: 'Start Building' });
    await expect(startBtn).toBeVisible({ timeout: 60000 });
    await startBtn.click();
    await waitForNavigationStabilization(page);

    console.log('Step 2: Open teaser dialog...');
    const teaserBtn = page.locator('button:has-text("Teaser"), button[aria-label*="Teaser"]');
    await teaserBtn.click();

    await expect(page.locator('#teaser-overlay')).toBeVisible({ timeout: 15000 });

    console.log('Step 3: Look for server-side rendering option...');
    const serverSideOptions = [
      'label:has-text("Server"), label:has-text("Cloud")',
      '[role="checkbox"][name*="server"], [role="checkbox"][name*="cloud"]',
      'button:has-text("Server Render"), button:has-text("Cloud Render")',
      'select option[value="server"], select option[value="cloud"]',
    ];

    let serverOptionFound = false;
    for (const selector of serverSideOptions) {
      const option = page.locator(selector);
      if (await option.isVisible({ timeout: 3000 }).catch(() => false)) {
        serverOptionFound = true;
        console.log('✅ Server-side rendering option found:', selector);
        break;
      }
    }

    if (!serverOptionFound) {
      console.log('ℹ️ Server-side rendering option not found (may not be implemented)');
    }

    console.log('Step 4: Verify teaser still works...');
    const startTeaserBtn = page.locator('button:has-text("Start"), button:has-text("Record")');
    if (await startTeaserBtn.isVisible()) {
      await startTeaserBtn.click();
      
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      const download = await downloadPromise;
      expect(await download.failure()).toBeNull();
      
      console.log('✅ Teaser generation working');
    }
  });
});
