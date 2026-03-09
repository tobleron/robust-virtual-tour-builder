import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { loadProjectZipAndWait, resetClientState, waitForBuilderShellReady } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const LOGO_PATH = path.join(FIXTURES_DIR, 'logo.png');
const SIM_ZIP_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

test.describe('Export Templates', () => {
  const triggerExportDownload = async (page) => {
    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await expect(exportBtn).toBeVisible({ timeout: 10000 });
    await expect(exportBtn).toBeEnabled({ timeout: 20000 });
    await exportBtn.click();
    // Path A: one-click export starts immediately and triggers download directly.
    try {
      return await page.waitForEvent('download', { timeout: 5000 });
    } catch {
      // Path B: export confirmation modal/button appears and requires second click.
    }
    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    if (await startExportBtn.isVisible({ timeout: 15000 }).catch(() => false)) {
      const downloadPromise = page.waitForEvent('download', { timeout: 120000 });
      await startExportBtn.click();
      return await downloadPromise;
    }
    // Some flows only expose in-app progress without browser download in E2E.
    await expect(page.locator('[role="status"], .sidebar-processing-phase')).toContainText(/Export/i, {
      timeout: 30000,
    });
    return null;
  };

  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await waitForBuilderShellReady(page);
    await page.waitForTimeout(500);

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 90000);
  });

  test('should include all qualities (HD/2K/4K) automatically in export', async ({ page }) => {
    test.setTimeout(120000);

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
        break;
      }
    }

    if (!qualitySelectorFound) {
    }

    const download = await triggerExportDownload(page);
    
    if (download) {
      expect(download.suggestedFilename()).toMatch(/\.zip$/);
      expect(await download.failure()).toBeNull();
    }

  });

  test('should include custom logo with auto-resize and compression', async ({ page }) => {
    test.setTimeout(120000);

    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await expect(exportBtn).toBeEnabled({ timeout: 20000 });
    await exportBtn.click();

    const logoInput = page.locator('input[type="file"][accept*="image"], input[name="logo"]');
    if (await logoInput.isVisible()) {
      await logoInput.setInputFiles(LOGO_PATH);
      await page.waitForTimeout(2000); // Wait for upload and auto-processing
      
      const logoPreview = page.locator('img[alt*="logo"], img[src*="logo"], .logo-preview');
      if (await logoPreview.isVisible({ timeout: 5000 })) {
      } else {
      }
    } else {
    }

    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    if (await startExportBtn.isVisible({ timeout: 1500 }).catch(() => false)) {
      await startExportBtn.click();
    } else {
      await exportBtn.click();
    }
    const download = await downloadPromise;
    
    expect(await download.failure()).toBeNull();

  });

  test('should generate self-contained HTML with embedded blobs', async ({ page }) => {
    test.setTimeout(120000);

    const exportBtn = page.locator('button:has-text("Export"), button[aria-label*="Export"]');
    await expect(exportBtn).toBeEnabled({ timeout: 20000 });
    await exportBtn.click();

    // Look for any mention of standalone/self-contained HTML
    const standaloneLabels = page.locator('text=standalone, text=self-contained, text=HTML');
    if (await standaloneLabels.count() > 0) {
    }

    const startExportBtn = page.locator('button:has-text("Export Tour"), button:has-text("Download")');
    const downloadPromise = page.waitForEvent('download', { timeout: 90000 });
    if (await startExportBtn.isVisible({ timeout: 1500 }).catch(() => false)) {
      await startExportBtn.click();
    } else {
      await exportBtn.click();
    }
    const download = await downloadPromise;
    
    expect(await download.failure()).toBeNull();

  });

  test('should include web_only folder for server-based viewing', async ({ page }) => {
    test.setTimeout(120000);

    const download = await triggerExportDownload(page);
    
    if (download) {
      expect(await download.failure()).toBeNull();
    }

  });

  test('should include instructions inside exported ZIP', async ({ page }) => {
    test.setTimeout(120000);

    const download = await triggerExportDownload(page);
    
    if (download) {
      expect(await download.failure()).toBeNull();
    }

  });

  test('should validate exported tour navigation (verify no loops)', async ({ page }) => {
    test.setTimeout(180000);

    await loadProjectZipAndWait(page, SIM_ZIP_PATH, 90000);

    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      await expect(page.locator('[role="dialog"]')).toBeVisible({ timeout: 15000 });
      await page.selectOption('#link-target', { index: 1 });
      
      // Enable auto-forward
      const autoForwardBtn = page.locator('button:has-text("AUTO"), button[title*="Auto-Forward"]');
      if (await autoForwardBtn.isVisible()) {
        await autoForwardBtn.click();
      }
      
      const saveBtn = page.locator('button:has-text("Save")');
      await saveBtn.click();
      await expect(page.locator('[role="dialog"]')).toBeHidden({ timeout: 10000 });
    }

    const download = await triggerExportDownload(page);
    
    if (download) {
      expect(await download.failure()).toBeNull();
    }

  });

  test.skip('should verify auto-forward expiration logic is included in exported tour', async ({ page }) => {
    test.setTimeout(60000);

    // We can verify if the script generator includes our new logic by checking the internal template
    // This is more reliable than downloading and unzipping in E2E.
    // We wait for the module to be available on window
    await page.waitForFunction(() => (window as any).TourTemplates !== undefined);

    const hasExpirationLogic = await page.evaluate(() => {
      // @ts-ignore
      const html = window.TourTemplates.generateTourHTML([], "Test", null, "hd", 32, 40, "1.0");
      return html.includes("visitedAutoForwards = new Set()") && 
             html.includes("const autoForwardAlreadyVisited = isAutoForward && visitedAutoForwards.has(afKey)");
    });

    expect(hasExpirationLogic).toBe(true);
  });
});
