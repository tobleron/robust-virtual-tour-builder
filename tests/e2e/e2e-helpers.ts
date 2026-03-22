import { expect, Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import type { Locator } from '@playwright/test';

const BACKEND_HEALTH_URL = process.env.E2E_BACKEND_HEALTH_URL ?? 'http://127.0.0.1:8080/health';
const STANDARD_PROJECT_ZIP =
  process.env.E2E_STANDARD_PROJECT_ZIP ??
  path.resolve(process.cwd(), 'tests/e2e/fixtures/tour.vt.zip');

/**
 * Sets up authentication for E2E tests.
 * This mocks the auth session endpoint and sets localStorage token.
 */
export async function setupAuthentication(page: Page, token = 'dev-token') {
  // Mock the auth session endpoint to return authenticated status
  await page.route('**/api/auth/me', async (route) => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        authenticated: true,
        user: {
          id: 'e2e-test-user',
          email: 'test@e2e.local',
          name: 'E2E Test User',
        },
      }),
    });
  });

  // Set auth token in localStorage and cookie before navigation
  await page.addInitScript((authToken) => {
    window.localStorage.setItem('auth_token', authToken);
    document.cookie = `auth_token=${authToken}; path=/; SameSite=Strict`;
  }, token);
}

/**
 * Resets client state (storage, caches, service workers).
 * Options:
 * - preserveAuthToken: Keep existing auth token across reset (default: false)
 * - authToken: Set a new auth token before navigation (will be preserved)
 * - gotoUrl: Navigate to this URL instead of /builder (default: '/builder')
 */
export async function resetClientState(
  page: Page,
  options?: {
    preserveAuthToken?: boolean;
    authToken?: string;
    gotoUrl?: string;
  },
) {
  const preserveAuthToken = options?.preserveAuthToken ?? false;
  const authToken = options?.authToken;
  const gotoUrl = options?.gotoUrl ?? '/builder';

  // Set auth token if provided
  if (authToken) {
    await page.addInitScript((token) => {
      window.localStorage.setItem('auth_token', token);
      document.cookie = `auth_token=${token}; path=/; SameSite=Strict`;
    }, authToken);
  }

  await page.goto(gotoUrl);
  await page.evaluate(async (preserveAuth) => {
    if ('serviceWorker' in navigator) {
      const regs = await navigator.serviceWorker.getRegistrations();
      await Promise.all(regs.map((reg) => reg.unregister()));
    }
    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }

    // Preserve auth token if requested
    const authToken = preserveAuth ? localStorage.getItem('auth_token') : null;

    localStorage.clear();
    sessionStorage.clear();

    if (preserveAuth && authToken) {
      localStorage.setItem('auth_token', authToken);
    }

    const dbs = await window.indexedDB.databases();
    await Promise.all(
      dbs
        .filter((db) => !!db.name)
        .map(
          (db) =>
            new Promise<void>((resolve) => {
              const req = window.indexedDB.deleteDatabase(db.name!);
              req.onsuccess = () => resolve();
              req.onerror = () => resolve();
              req.onblocked = () => resolve();
            }),
        ),
    );
  }, preserveAuthToken);
  await page.reload();
}

export async function waitForBuilderShellReady(page: Page, timeoutMs = 30000) {
  const startTime = Date.now();
  const halfTimeout = timeoutMs / 2;

  // Wait for backend to be ready first
  await waitForBackendReady(page, timeoutMs);

  // Check if we're on the correct route
  const currentUrl = page.url();
  if (!currentUrl.includes('/builder')) {
    console.log(`[E2E] Warning: Not on /builder route, current URL: ${currentUrl}`);
  }

  // Wait for sidebar element first (parent container)
  try {
    await expect(page.locator('#sidebar')).toBeVisible({ timeout: timeoutMs });
  } catch (error) {
    const currentUrl = page.url();
    const pageTitle = await page.title().catch(() => 'unknown');
    throw new Error(
      `Sidebar not found within ${timeoutMs}ms. ` +
        `Current URL: ${currentUrl}, Page title: ${pageTitle}. ` +
        `This may indicate authentication redirect or initialization failure.`,
    );
  }

  // Wait for upload elements with intermediate debugging
  try {
    await expect(page.locator('#sidebar-project-upload')).toHaveCount(1, { timeout: halfTimeout });
  } catch (firstError) {
    const elapsed = Date.now() - startTime;
    const sidebarContent = await page.locator('#sidebar').innerHTML().catch(() => 'not accessible');
    console.log(
      `[E2E] #sidebar-project-upload not found after ${elapsed}ms. Sidebar content length: ${sidebarContent.length}`,
    );

    // Check if we might be on a different route (like /signin)
    const currentUrl = page.url();
    if (currentUrl.includes('/signin')) {
      throw new Error(
        `Redirected to signin page. Authentication not properly set up. Current URL: ${currentUrl}`,
      );
    }

    // Retry with remaining timeout
    const remainingTimeout = timeoutMs - elapsed;
    if (remainingTimeout > 5000) {
      await expect(page.locator('#sidebar-project-upload')).toHaveCount(1, {
        timeout: remainingTimeout,
      });
    } else {
      throw firstError;
    }
  }

  await expect(page.locator('#sidebar-image-upload')).toHaveCount(1, { timeout: timeoutMs / 2 });

  const totalTime = Date.now() - startTime;
  console.log(`[E2E] Builder shell ready in ${totalTime}ms`);
}

export function sceneItems(page: Page): Locator {
  return page.locator('.scene-item, button[aria-label^="Select scene "]');
}

export function sceneItem(page: Page, index: number): Locator {
  return sceneItems(page).nth(index);
}

export function imageUploadInput(page: Page) {
  return page.locator('#sidebar-image-upload');
}

export async function clickStartBuildingIfVisible(page: Page, timeoutMs = 90000) {
  const startBtn = page.getByRole('button', { name: /Start Building|Close|Continue/i }).first();
  try {
    await startBtn.waitFor({ state: 'visible', timeout: Math.min(timeoutMs, 15000) });
    await startBtn.click();
  } catch {
    // Some flows auto-complete without showing the summary modal.
  }
}

async function waitForProjectHydration(page: Page, timeoutMs = 90000) {
  const deadline = Date.now() + timeoutMs;
  const actionBtn = page.getByRole('button', { name: /Start Building|Close|Continue/i }).first();

  while (Date.now() < deadline) {
    const visible = await actionBtn.isVisible().catch(() => false);
    if (visible) {
      const enabled = await actionBtn.isEnabled().catch(() => false);
      if (enabled) {
        await actionBtn.click().catch(() => undefined);
      }
    }

    const sceneCount = await sceneItems(page).count().catch(() => 0);
    if (sceneCount >= 1) return;
    await page.waitForTimeout(300);
  }

  const statusText = await page
    .locator('.processing-status, [role="status"]')
    .allTextContents()
    .catch(() => []);
  throw new Error(`Project hydration timeout. Scene count remained 0. Status: ${statusText.join(' | ')}`);
}

export async function waitForSidebarInteractive(page: Page, timeoutMs = 90000) {
  const newButton = page.getByRole('button', { name: 'New' });
  const modalActionButton = page.getByRole('button', { name: /Start Building|Close|Continue/i }).first();
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    const modalVisible = await modalActionButton.isVisible().catch(() => false);
    if (modalVisible) {
      const modalEnabled = await modalActionButton.isEnabled().catch(() => false);
      if (modalEnabled) {
        await modalActionButton.click();
      }
    }

    const lockOverlay = page.locator('.interaction-lock-overlay');
    if ((await lockOverlay.count()) > 0) {
      await lockOverlay.first().waitFor({ state: 'hidden', timeout: 3000 }).catch(() => undefined);
    }

    const isReady = await newButton.isEnabled().catch(() => false);
    if (isReady) return;
    await page.waitForTimeout(250);
  }

  throw new Error(`Sidebar did not become interactive within ${timeoutMs}ms`);
}

export async function waitForBackendReady(page: Page, timeoutMs = 90000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const serverOk = await page.request
      .get(BACKEND_HEALTH_URL)
      .then(async (res) => {
        if (!res.ok()) return false;
        const json = await res.json().catch(() => null);
        return json?.status === 'ok';
      })
      .catch(() => false);

    const browserOk = await page
      .evaluate(async (healthUrl) => {
        try {
          const res = await fetch(healthUrl, { method: 'GET' });
          if (!res.ok) return false;
          const json = await res.json().catch(() => null);
          return json?.status === 'ok';
        } catch {
          return false;
        }
      }, BACKEND_HEALTH_URL)
      .catch(() => false);

    if (serverOk && browserOk) return;
    await page.waitForTimeout(300);
  }

  throw new Error(`Backend did not become healthy within ${timeoutMs}ms`);
}

export async function uploadImageAndWaitForSceneCount(
  page: Page,
  imagePath: string,
  expectedSceneCount: number,
  timeoutMs = 90000,
) {
  await waitForBackendReady(page, timeoutMs);

  const maxAttempts = 1;
  let lastError: unknown = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    const attemptBudget = Math.max(15000, Math.floor(timeoutMs / maxAttempts));
    const fileInput = imageUploadInput(page);
    await fileInput.setInputFiles([imagePath]);
    await clickStartBuildingIfVisible(page, attemptBudget);

    try {
      await waitForSidebarInteractive(page, attemptBudget);
      await expect
        .poll(async () => sceneItems(page).count(), { timeout: attemptBudget })
        .toBeGreaterThanOrEqual(expectedSceneCount);
      lastError = null;
      break;
    } catch (err) {
      lastError = err;
      const cancelBtn = page.getByRole('button', { name: /^Cancel$/ }).first();
      if (await cancelBtn.isVisible().catch(() => false)) {
        await cancelBtn.click().catch(() => undefined);
      }
      await page.waitForTimeout(800);
      await waitForSidebarInteractive(page, attemptBudget).catch(() => undefined);
    }
  }

  if (lastError) {
    const statusText = await page
      .locator('.processing-status, [role="status"]')
      .allTextContents()
      .catch(() => []);
    throw new Error(
      `Scene count did not reach ${expectedSceneCount}. Status: ${statusText.join(' | ')}. ${String(lastError)}`,
    );
  }

  const lockOverlay = page.locator('.interaction-lock-overlay');
  if ((await lockOverlay.count()) > 0) {
    await expect(lockOverlay).not.toBeVisible({ timeout: timeoutMs });
  }
}

export async function loadProjectZipAndWait(page: Page, zipPath: string, timeoutMs = 90000) {
  await waitForBackendReady(page, timeoutMs);
  const fileInput = page.locator('#sidebar-project-upload');
  await expect(fileInput).toHaveCount(1, { timeout: Math.min(timeoutMs, 15000) });
  await fileInput.setInputFiles(zipPath);
  const fileCount = await fileInput.evaluate((el: HTMLInputElement) => el.files?.length ?? 0);
  if (fileCount < 1) {
    throw new Error('Zip file input did not receive selected file');
  }
  await fileInput.dispatchEvent('change');
  await clickStartBuildingIfVisible(page, timeoutMs);
  await waitForProjectHydration(page, timeoutMs);
  await waitForSidebarInteractive(page, timeoutMs);
  await waitForNavigationStabilization(page, Math.min(timeoutMs, 30000));
}

export async function loadStandardProject(page: Page, timeoutMs = 90000) {
  if (!fs.existsSync(STANDARD_PROJECT_ZIP)) {
    throw new Error(`Standard project zip not found: ${STANDARD_PROJECT_ZIP}`);
  }
  await loadProjectZipAndWait(page, STANDARD_PROJECT_ZIP, timeoutMs);
}

export async function waitForNavigationStabilization(page: Page, timeoutMs = 30000) {
  await page
    .waitForFunction(() => {
      const state = (window as any).store?.state;
      const fsm = state?.navigationState?.navigationFsm;
      if (!fsm) return false;
      if (typeof fsm === 'string') return fsm === 'IdleFsm';
      return fsm?.TAG === 0;
    }, { timeout: timeoutMs })
    .catch(() => undefined);
}

export async function waitForViewerReady(page: Page, timeoutMs = 45000) {
  await expect(page.locator('#panorama-a.active, #panorama-b.active').first()).toBeVisible({
    timeout: timeoutMs,
  });
  await expect(page.locator('#react-hotspot-layer')).toBeVisible({ timeout: timeoutMs });
  await expect(page.getByRole('alert').filter({ hasText: 'Viewer not initialized' })).toHaveCount(0, {
    timeout: timeoutMs,
  });
}

export async function createHotspotAtViewerCenter(page: Page) {
  const viewer = page.locator('#viewer-stage');
  await expect(viewer).toBeVisible({ timeout: 30000 });
  const box = await viewer.boundingBox();
  if (!box) throw new Error('Viewer not found');

  await page.keyboard.down('Alt');
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.keyboard.up('Alt');
}

export async function selectFirstLinkTarget(page: Page) {
  const select = page.locator('#link-target');
  await expect(select).toBeVisible({ timeout: 10000 });

  const options = select.locator('option');
  const optionCount = await options.count();
  expect(optionCount).toBeGreaterThan(1);

  const firstTargetValue = await options.nth(1).getAttribute('value');
  if (!firstTargetValue) {
    throw new Error('No link target value found at index 1');
  }

  await page.selectOption('#link-target', firstTargetValue);
}
