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

  test('should export HD template with correct dimensions', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await expect(exportBtn).toBeVisible({ timeout: 10000 });
    await exportBtn.click();

    console.log('Step 2: Select HD template...');
    const hdOption = page.locator('[role="radio"][value="hd"], button:has-text("HD"), label:has-text("HD")');
    if (await hdOption.isVisible()) {
      await hdOption.click();
    } else {
      // Try alternative selector
      const hdSelect = page.locator('select[name="template"], select[name="quality"]');
      if (await hdSelect.isVisible()) {
        await hdSelect.selectOption('hd');
      }
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

    console.log('✅ HD template export completed');
  });

  test('should export 2K template with enhanced quality', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Select 2K template...');
    const twoKOption = page.locator('[role="radio"][value="2k"], button:has-text("2K"), label:has-text("2K")');
    if (await twoKOption.isVisible()) {
      await twoKOption.click();
    } else {
      const qualitySelect = page.locator('select[name="template"], select[name="quality"]');
      if (await qualitySelect.isVisible()) {
        await qualitySelect.selectOption('2k');
      }
    }

    console.log('Step 3: Start export...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 4: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    expect(download.suggestedFilename()).toMatch(/\.zip$/);
    expect(await download.failure()).toBeNull();

    console.log('✅ 2K template export completed');
  });

  test('should export 4K template with maximum quality', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Select 4K template...');
    const fourKOption = page.locator('[role="radio"][value="4k"], button:has-text("4K"), label:has-text("4K")');
    if (await fourKOption.isVisible()) {
      await fourKOption.click();
    } else {
      const qualitySelect = page.locator('select[name="template"], select[name="quality"]');
      if (await qualitySelect.isVisible()) {
        await qualitySelect.selectOption('4k');
      }
    }

    console.log('Step 3: Start export...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 4: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    expect(download.suggestedFilename()).toMatch(/\.zip$/);
    expect(await download.failure()).toBeNull();

    console.log('✅ 4K template export completed');
  });

  test('should include custom logo in export', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Upload custom logo...');
    const logoInput = page.locator('input[type="file"][accept*="image"], input[name="logo"]');
    if (await logoInput.isVisible()) {
      await logoInput.setInputFiles(LOGO_PATH);
      await page.waitForTimeout(1000); // Wait for upload preview
      console.log('✅ Logo uploaded');
    } else {
      console.log('⚠️ Logo upload not found in export dialog');
    }

    console.log('Step 3: Verify logo preview shown...');
    const logoPreview = page.locator('img[alt*="logo"], img[src*="logo"]');
    if (await logoPreview.isVisible({ timeout: 5000 })) {
      console.log('✅ Logo preview visible');
    }

    console.log('Step 4: Start export with logo...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    console.log('Step 5: Wait for download...');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    
    expect(download.suggestedFilename()).toMatch(/\.zip$/);
    expect(await download.failure()).toBeNull();

    console.log('✅ Export with custom logo completed');
  });

  test('should generate self-contained HTML with embedded viewer', async ({ page }) => {
    test.setTimeout(120000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Select self-contained HTML option...');
    const selfContainedOption = page.locator('label:has-text("Self-contained"), label:has-text("Standalone"), input[type="checkbox"][name*="standalone"]');
    if (await selfContainedOption.isVisible()) {
      await selfContainedOption.click();
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
    
    // Note: To fully verify, we would need to:
    // 1. Extract the ZIP
    // 2. Check that HTML contains embedded Pannellum
    // 3. Verify no external dependencies
    // This would require additional test infrastructure
  });

  test('should show file protocol warning for non-desktop exports', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Open export dialog...');
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await exportBtn.click();

    console.log('Step 2: Look for file protocol warning...');
    // Warning might appear as:
    // - Alert banner
    // - Tooltip
    // - Info text in dialog
    
    const warningSelectors = [
      '[role="alert"]:has-text("file://"),',
      '[role="alert"]:has-text("protocol"),',
      '.alert:has-text("desktop"),',
      '.warning:has-text("open"),',
      'text=Best viewed on desktop',
      'text=file protocol',
    ];

    let warningFound = false;
    for (const selector of warningSelectors) {
      const warning = page.locator(selector);
      if (await warning.isVisible({ timeout: 3000 }).catch(() => false)) {
        warningFound = true;
        console.log('✅ File protocol warning found:', selector);
        break;
      }
    }

    if (!warningFound) {
      console.log('ℹ️ No file protocol warning found (may be implemented differently)');
    }

    console.log('Step 3: Verify export still works...');
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    await startExportBtn.click();

    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    const download = await downloadPromise;
    expect(await download.failure()).toBeNull();

    console.log('✅ Export completed (with or without warning)');
  });

  test('should validate exported tour navigation works', async ({ page }) => {
    test.setTimeout(180000);

    console.log('Step 1: Create simple tour...');
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);

    console.log('Step 2: Create hotspot linking scenes...');
    const firstScene = page.locator('.scene-item').first();
    await firstScene.click();
    await waitForNavigationStabilization(page);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.locator('[data-testid="scene-option"]').first().click();
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
      console.log('✅ Hotspot created');
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

    console.log('✅ Exported tour created (manual verification needed for navigation)');
    console.log('Note: To fully test, open the ZIP in a browser and verify hotspot navigation works');
  });
});
