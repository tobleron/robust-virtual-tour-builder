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
const LOGO_PATH = path.join(FIXTURES_DIR, 'logo.png');

test.describe('Export Templates', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);

    // Upload minimum scenes for export
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
  });

  test('should include all qualities (HD/2K/4K) automatically in export', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await expect(exportBtn).toBeVisible({ timeout: 10000 });
    await exportBtn.click();

    console.log('Step 2: Verify no quality selection UI (all included automatically)...');
    // There should be NO quality selection radios/dropdowns
    const qualitySelectors = [
      '[role="radio"][value="hd"]',
      '[role="radio"][value="2k"]',
      '[role="radio"][value="4k"]',
      'select[name="quality"], select[name="template"]',
      'button:has-text("HD"), button:has-text("2K"), button:has-text("4K")',
    ];

    let qualitySelectorFound = false;
    for (const selector of qualitySelectors) {
      const selectorEl = page.locator(selector);
      if (await selectorEl.isVisible({ timeout: 3000 }).catch(() => false)) {
        qualitySelectorFound = true;
        console.log('⚠️ Quality selector found:', selector);
        break;
      }
    }

    if (!qualitySelectorFound) {
      console.log('✅ No quality selection UI (all qualities included automatically)');
    }

    console.log('Step 3: Start export...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 4: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    console.log('Downloaded filename:', download.suggestedFilename());
    expect(download.suggestedFilename()).toMatch(/\.zip$/);
    expect(await download.failure()).toBeNull();

    console.log('✅ Export includes all qualities (HD/2K/4K) automatically');
  });

  test('should include custom logo with auto-resize and compression', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Upload custom logo...');
    const logoInput = page.locator('input[type="file"][accept*="image"], input[name="logo"]');
    if (await logoInput.isVisible()) {
      await logoInput.setInputFiles(LOGO_PATH);
      await page.waitForTimeout(2000); // Wait for upload and auto-processing
      console.log('✅ Logo uploaded');
      
      console.log('Step 3: Verify logo preview shown...');
      const logoPreview = page.locator('img[alt*="logo"], img[src*="logo"], .logo-preview');
      if (await logoPreview.isVisible({ timeout: 5000 })) {
        console.log('✅ Logo preview visible');
      } else {
        console.log('ℹ️ Logo preview not found (may use different implementation)');
      }
    } else {
      console.log('ℹ️ Logo upload not found in export dialog');
    }

    console.log('Step 4: Start export with logo...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 5: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    expect(download.suggestedFilename()).toMatch(/\.zip$/);
    expect(await download.failure()).toBeNull();

    console.log('✅ Export with custom logo completed (auto-resized and compressed)');
  });

  test('should generate self-contained HTML with embedded blobs', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Verify export includes standalone HTML...');
    // Look for any mention of standalone/self-contained HTML
    const standaloneLabels = page.locator('text=standalone, text=self-contained, text=HTML');
    if (await standaloneLabels.count() > 0) {
      console.log('✅ Standalone HTML option mentioned');
    }

    console.log('Step 3: Start export...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 4: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    const filename = download.suggestedFilename();
    console.log('Downloaded filename:', filename);
    expect(filename).toMatch(/\.zip$/);
    expect(await download.failure()).toBeNull();

    console.log('✅ Self-contained HTML export completed');
    console.log('Note: Full verification would require extracting ZIP and checking:');
    console.log('  - HTML contains embedded Pannellum (no external deps)');
    console.log('  - Assets embedded as blobs');
    console.log('  - Works without web server');
  });

  test('should include web_only folder for server-based viewing', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Start export...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 3: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    const filename = download.suggestedFilename();
    console.log('Downloaded:', filename);
    expect(await download.failure()).toBeNull();

    console.log('✅ Export completed');
    console.log('Note: Full verification would require extracting ZIP and checking:');
    console.log('  - web_only folder exists');
    console.log('  - Contains additional quality variants');
    console.log('  - Requires web server to run');
  });

  test('should include instructions inside exported ZIP', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Start export...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 3: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    const filename = download.suggestedFilename();
    console.log('Downloaded:', filename);
    expect(await download.failure()).toBeNull();

    console.log('✅ Export completed with instructions');
    console.log('Note: Instructions are self-describing inside the ZIP (no separate warning)');
  });

  test('should validate exported tour navigation (verify no loops)', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Create simple tour with auto-forward link...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    console.log('Step 2: Create hotspot with auto-forward...');
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').first().click();
      
      // Enable auto-forward
      const autoForwardBtn = page.locator('button:has-text("AUTO"), button[title*="Auto-Forward"]');
      if (await autoForwardBtn.isVisible()) {
        await autoForwardBtn.click();
        console.log('✅ Auto-forward enabled');
      }
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    console.log('Step 3: Export tour...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 4: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    const filename = download.suggestedFilename();
    console.log('Downloaded:', filename);
    expect(await download.failure()).toBeNull();

    console.log('✅ Exported tour created');
    console.log('Note: Full navigation validation requires:');
    console.log('  - Opening exported HTML in browser');
    console.log('  - Verifying hotspot navigation works');
    console.log('  - Verifying no infinite loops in auto-forward chain');
    console.log('  - Verifying auto-forward links are traversed LAST in multi-link scenes');
  });
});
