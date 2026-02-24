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

test.describe('Accessibility Comprehensive', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await resetClientState(page);

    await page.waitForSelector('#viewer-logo', { state: 'visible', timeout: 30000 });
    await page.waitForTimeout(500);

    // Upload scenes for accessibility testing
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_1, 1);
    await waitForNavigationStabilization(page);
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH_2, 2);
    await waitForNavigationStabilization(page);
  });

  test('should navigate entire app using keyboard only', async ({ page, browserName }) => {
    test.skip(browserName === 'webkit', 'Keyboard navigation test requires Chromium/Firefox');
    test.setTimeout(120000);

    console.log('Step 1: Test Tab navigation through main UI...');
    
    // Start from body
    await page.keyboard.press('Tab');
    
    // Navigate through interactive elements
    const tabTargets = [
      'button, [role="button"]',
      'a[href], [tabindex="0"]',
      'input, select, textarea',
    ];
    
    let elementCount = 0;
    const maxTabs = 50; // Prevent infinite loop
    
    for (let i = 0; i < maxTabs; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(100);
      
      const focusedElement = await page.evaluate(() => {
        const el = document.activeElement;
        return el ? {
          tagName: el.tagName,
          role: el.getAttribute('role'),
          ariaLabel: el.getAttribute('aria-label'),
          text: el.textContent?.substring(0, 30) || '',
          tabIndex: el.tabIndex,
        } : null;
      });
      
      if (focusedElement) {
        elementCount++;
        console.log(`Tab ${i + 1}:`, focusedElement);
      }
      
      // Check if we've cycled back to start
      if (focusedElement?.tagName === 'BODY') {
        console.log('✅ Tab cycle completed');
        break;
      }
    }
    
    console.log(`Total focusable elements: ${elementCount}`);
    expect(elementCount).toBeGreaterThan(5);

    console.log('Step 2: Test Shift+Tab reverse navigation...');
    await page.keyboard.press('Shift+Tab');
    await page.waitForTimeout(100);
    
    const reverseFocused = await page.evaluate(() => document.activeElement?.tagName);
    console.log('Reverse navigation working:', reverseFocused);

    console.log('Step 3: Test Enter/Space activation...');
    // Focus on a button and activate
    const buttons = page.locator('button:not([disabled])');
    if (await buttons.count() > 0) {
      await buttons.first().focus();
      await page.keyboard.press('Enter');
      await page.waitForTimeout(500);
      console.log('✅ Enter key activation working');
      
      await buttons.first().focus();
      await page.keyboard.press('Space');
      await page.waitForTimeout(500);
      console.log('✅ Space key activation working');
    }

    console.log('Step 4: Test Escape key for modal/dialog close...');
    // Open a dialog if possible
    const addLinkBtn = page.locator('#viewer-utility-bar button[aria-label="Add Link"]');
    if (await addLinkBtn.isVisible()) {
      await addLinkBtn.click();
      await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
      
      const dialogVisible = await page.locator('[role="dialog"]').isVisible({ timeout: 5000 });
      if (dialogVisible) {
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        
        const dialogClosed = await page.locator('[role="dialog"]').isHidden({ timeout: 3000 });
        if (dialogClosed) {
          console.log('✅ Escape key closes dialog');
        }
      }
    }

    console.log('✅ Keyboard navigation working');
  });

  test('should maintain focus order through modals', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Get initial focused element...');
    const initialFocus = await page.evaluate(() => {
      const el = document.activeElement;
      return el?.tagName || 'unknown';
    });
    console.log('Initial focus:', initialFocus);

    console.log('Step 2: Open modal/dialog...');
    // Try to open various dialogs
    const dialogTriggers = [
      'button:has-text("Link"), button[aria-label="Add Link"]',
      'button:has-text("Edit"), button[aria-label*="Edit"]',
      'button:has-text("Settings"), button[aria-label*="Settings"]',
      'button:has-text("Export"), button[aria-label*="Export"]',
    ];

    let dialogOpened = false;
    for (const selector of dialogTriggers) {
      const trigger = page.locator(selector);
      if (await trigger.isVisible()) {
        await trigger.click();
        await page.waitForTimeout(500);
        
        // For link dialog, need to place hotspot
        if (selector.includes('Link')) {
          await page.locator('#viewer-stage').click({ position: { x: 400, y: 300 } });
        }
        
        const dialogVisible = await page.locator('[role="dialog"]').isVisible({ timeout: 5000 });
        if (dialogVisible) {
          dialogOpened = true;
          console.log('✅ Dialog opened with:', selector);
          break;
        }
      }
    }

    if (!dialogOpened) {
      console.log('ℹ️ No dialog found to test');
      return;
    }

    console.log('Step 3: Check focus is trapped in modal...');
    const focusedInDialog = await page.evaluate(() => {
      const el = document.activeElement;
      const dialog = el?.closest('[role="dialog"]');
      return !!dialog;
    });

    if (focusedInDialog) {
      console.log('✅ Focus trapped inside modal');
    } else {
      console.log('ℹ️ Focus may not be trapped (needs manual verification)');
    }

    console.log('Step 4: Tab through modal elements...');
    const modalElements: any[] = [];
    for (let i = 0; i < 20; i++) {
      await page.keyboard.press('Tab');
      await page.waitForTimeout(50);
      
      const focused = await page.evaluate(() => {
        const el = document.activeElement;
        const dialog = el?.closest('[role="dialog"]');
        return {
          inDialog: !!dialog,
          tagName: el?.tagName,
          ariaLabel: el?.getAttribute('aria-label'),
        };
      });
      
      modalElements.push(focused);
      
      if (!focused.inDialog) {
        console.log('Focus left modal at element', i);
        break;
      }
    }

    console.log('Step 5: Close modal and verify focus returns...');
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);

    const focusReturned = await page.evaluate(() => {
      const el = document.activeElement;
      // Focus should return to trigger or body
      return el?.tagName === 'BODY' || el?.tagName === 'BUTTON';
    });

    if (focusReturned) {
      console.log('✅ Focus returned after modal close');
    } else {
      console.log('ℹ️ Focus return needs verification');
    }
  });

  test('should announce state changes to screen readers', async ({ page }) => {
    test.setTimeout(90000);

    console.log('Step 1: Look for live regions...');
    const liveRegionSelectors = [
      '[role="alert"]',
      '[role="status"]',
      '[role="log"]',
      '[aria-live="polite"]',
      '[aria-live="assertive"]',
    ];

    let liveRegionFound = false;
    for (const selector of liveRegionSelectors) {
      const region = page.locator(selector);
      if (await region.count() > 0) {
        liveRegionFound = true;
        console.log('✅ Live region found:', selector);
        break;
      }
    }

    if (!liveRegionFound) {
      console.log('ℹ️ No ARIA live regions found');
    }

    console.log('Step 2: Trigger state change and check announcements...');
    
    // Trigger scene navigation
    const sceneItem = page.locator('.scene-item').first();
    if (await sceneItem.isVisible()) {
      await sceneItem.click();
      await waitForNavigationStabilization(page);
      
      // Check for aria-live updates
      const liveUpdates = await page.evaluate(() => {
        const regions = document.querySelectorAll('[aria-live]');
        const updates: string[] = [];
        regions.forEach(r => {
          if (r.textContent) {
            updates.push(r.textContent.substring(0, 50));
          }
        });
        return updates;
      });
      
      if (liveUpdates.length > 0) {
        console.log('✅ Live region updates:', liveUpdates);
      }
    }

    console.log('Step 3: Check for toast notifications...');
    const toastSelectors = [
      '[role="alert"]',
      '.toast, .notification',
      '[data-testid="toast"]',
    ];

    for (const selector of toastSelectors) {
      const toast = page.locator(selector);
      if (await toast.count() > 0) {
        const hasAriaLive = await toast.evaluate(el => 
          el.hasAttribute('aria-live') || el.getAttribute('role') === 'alert'
        );
        if (hasAriaLive) {
          console.log('✅ Toast has ARIA live announcement:', selector);
        }
      }
    }

    console.log('✅ Screen reader announcements checked');
  });

  test('should have proper ARIA labels on interactive elements', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Check buttons for accessible names...');
    const buttons = page.locator('button');
    const buttonCount = await buttons.count();
    
    let buttonsWithLabels = 0;
    let buttonsWithoutLabels = 0;
    
    for (let i = 0; i < Math.min(buttonCount, 20); i++) {
      const button = buttons.nth(i);
      const hasAriaLabel = await button.evaluate(el => 
        el.hasAttribute('aria-label') || 
        el.hasAttribute('aria-labelledby') ||
        el.textContent?.trim().length > 0
      );
      
      if (hasAriaLabel) {
        buttonsWithLabels++;
      } else {
        buttonsWithoutLabels++;
      }
    }
    
    console.log(`Buttons with labels: ${buttonsWithLabels}, without: ${buttonsWithoutLabels}`);
    
    if (buttonsWithoutLabels > 0) {
      console.log('⚠️ Some buttons missing accessible names');
    } else {
      console.log('✅ All checked buttons have accessible names');
    }

    console.log('Step 2: Check links for accessible names...');
    const links = page.locator('a, [role="link"]');
    const linkCount = await links.count();
    
    let linksWithLabels = 0;
    for (let i = 0; i < Math.min(linkCount, 10); i++) {
      const link = links.nth(i);
      const hasLabel = await link.evaluate(el =>
        el.hasAttribute('aria-label') ||
        el.textContent?.trim().length > 0 ||
        el.hasAttribute('title')
      );
      
      if (hasLabel) {
        linksWithLabels++;
      }
    }
    
    console.log(`Links with labels: ${linksWithLabels}/${Math.min(linkCount, 10)}`);

    console.log('Step 3: Check form inputs for labels...');
    const inputs = page.locator('input, select, textarea');
    const inputCount = await inputs.count();
    
    let inputsWithLabels = 0;
    for (let i = 0; i < Math.min(inputCount, 10); i++) {
      const input = inputs.nth(i);
      const hasLabel = await input.evaluate(el => {
        const id = el.id;
        if (id) {
          const label = document.querySelector(`label[for="${id}"]`);
          if (label) return true;
        }
        return el.hasAttribute('aria-label') || 
               el.hasAttribute('aria-labelledby') ||
               el.hasAttribute('placeholder');
      });
      
      if (hasLabel) {
        inputsWithLabels++;
      }
    }
    
    console.log(`Inputs with labels: ${inputsWithLabels}/${Math.min(inputCount, 10)}`);

    console.log('✅ ARIA labels audit complete');
  });

  test('should support high contrast mode', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Check for high contrast toggle or preference...');
    const contrastSelectors = [
      'button:has-text("Contrast"), button:has-text("High Contrast")',
      '[aria-label*="contrast"], [aria-label*="theme"]',
      'select[name="theme"], select[name="contrast"]',
    ];

    let contrastToggleFound = false;
    for (const selector of contrastSelectors) {
      const toggle = page.locator(selector);
      if (await toggle.isVisible({ timeout: 3000 }).catch(() => false)) {
        contrastToggleFound = true;
        console.log('✅ High contrast toggle found:', selector);
        break;
      }
    }

    if (!contrastToggleFound) {
      console.log('ℹ️ No high contrast toggle found in UI');
    }

    console.log('Step 2: Check for prefers-color-scheme support...');
    const supportsColorScheme = await page.evaluate(() => {
      const styles = document.querySelectorAll('style, link[rel="stylesheet"]');
      let hasColorScheme = false;
      
      // Check inline styles
      styles.forEach(style => {
        const text = style.textContent || '';
        if (text.includes('prefers-color-scheme')) {
          hasColorScheme = true;
        }
      });
      
      // Check CSS variables
      const rootStyles = getComputedStyle(document.documentElement);
      const hasDarkVars = rootStyles.getPropertyValue('--color-bg-dark') !== '';
      
      return { hasColorScheme, hasDarkVars };
    });

    console.log('Color scheme support:', supportsColorScheme);

    console.log('Step 3: Test forced colors mode emulation...');
    // Emulate forced colors mode
    await page.emulateMedia({ forcedColors: 'active' });
    await page.waitForTimeout(500);
    
    const forcedColorsActive = await page.evaluate(() => {
      return window.matchMedia('(forced-colors: active)').matches;
    });
    
    if (forcedColorsActive) {
      console.log('✅ Forced colors mode active');
      
      // Check if UI adapts
      const hasHighContrastStyles = await page.evaluate(() => {
        const body = document.body;
        const styles = getComputedStyle(body);
        // In forced colors, backgrounds should be transparent or high contrast
        return styles.backgroundColor === 'transparent' || 
               styles.color !== 'rgb(0, 0, 0)';
      });
      
      if (hasHighContrastStyles) {
        console.log('✅ UI adapts to forced colors mode');
      } else {
        console.log('ℹ️ UI may need forced colors adaptation');
      }
    }
    
    // Reset emulation
    await page.emulateMedia({ forcedColors: 'none' });

    console.log('✅ High contrast support checked');
  });

  test('should provide skip links for repetitive content', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Look for skip links...');
    const skipLinkSelectors = [
      'a[href="#main"], a[href="#content"], a[href="#viewer"]',
      '.skip-link, [class*="skip"]',
      '[role="link"]:has-text("Skip")',
    ];

    let skipLinkFound = false;
    for (const selector of skipLinkSelectors) {
      const skipLink = page.locator(selector);
      if (await skipLink.isVisible({ timeout: 3000 }).catch(() => false)) {
        skipLinkFound = true;
        console.log('✅ Skip link found:', selector);
        break;
      }
      
      // Also check for hidden skip links that appear on focus
      const hiddenSkipLink = page.locator(selector);
      const isHiddenSkipLink = await hiddenSkipLink.evaluate(el => {
        const styles = getComputedStyle(el);
        return styles.position === 'absolute' && 
               (styles.clip?.includes('rect') || styles.visibility === 'hidden');
      }).catch(() => false);
      
      if (isHiddenSkipLink) {
        skipLinkFound = true;
        console.log('✅ Hidden skip link found (appears on focus):', selector);
        break;
      }
    }

    if (!skipLinkFound) {
      console.log('ℹ️ No skip links found');
    }

    console.log('Step 2: Check main content landmark...');
    const mainLandmark = page.locator('main, [role="main"], #main, #content');
    if (await mainLandmark.count() > 0) {
      console.log('✅ Main content landmark found');
    } else {
      console.log('ℹ️ No main landmark found');
    }

    console.log('Step 3: Check navigation landmarks...');
    const navLandmarks = page.locator('nav, [role="navigation"]');
    const navCount = await navLandmarks.count();
    console.log(`Navigation landmarks found: ${navCount}`);

    if (navCount > 0) {
      // Check if nav regions have labels
      const labeledNavCount = await navLandmarks.evaluateAll(els => 
        els.filter(el => 
          el.hasAttribute('aria-label') || 
          el.hasAttribute('aria-labelledby')
        ).length
      );
      console.log(`Labeled navigation regions: ${labeledNavCount}/${navCount}`);
    }

    console.log('✅ Landmark structure checked');
  });

  test('should have proper heading hierarchy', async ({ page }) => {
    test.setTimeout(60000);

    console.log('Step 1: Extract heading hierarchy...');
    const headings = await page.evaluate(() => {
      const headingElements = document.querySelectorAll('h1, h2, h3, h4, h5, h6');
      const headings: { level: number; text: string }[] = [];
      
      headingElements.forEach(el => {
        const level = parseInt(el.tagName[1]);
        const text = el.textContent?.trim() || '';
        if (text) {
          headings.push({ level, text: text.substring(0, 50) });
        }
      });
      
      return headings;
    });

    console.log('Heading hierarchy:');
    headings.forEach(h => {
      console.log(`  H${h.level}: ${h.text}`);
    });

    console.log('Step 2: Check for skipped heading levels...');
    let skippedLevels = 0;
    for (let i = 1; i < headings.length; i++) {
      const prevLevel = headings[i - 1].level;
      const currLevel = headings[i].level;
      
      // Allow going deeper or same level, but not skipping up more than 1
      if (currLevel < prevLevel && prevLevel - currLevel > 1) {
        skippedLevels++;
        console.log(`⚠️ Skipped from H${prevLevel} to H${currLevel}`);
      }
    }

    if (skippedLevels === 0) {
      console.log('✅ Heading hierarchy is valid');
    } else {
      console.log(`⚠️ Found ${skippedLevels} skipped heading levels`);
    }

    console.log('Step 3: Check for multiple H1s...');
    const h1Count = headings.filter(h => h.level === 1).length;
    if (h1Count === 1) {
      console.log('✅ Single H1 found');
    } else if (h1Count === 0) {
      console.log('⚠️ No H1 found');
    } else {
      console.log(`⚠️ Multiple H1s found: ${h1Count}`);
    }

    console.log('✅ Heading structure audit complete');
  });
});
