import { expect, Page } from '@playwright/test';

export async function resetClientState(page: Page) {
  await page.goto('/');
  await page.evaluate(async () => {
    if ('serviceWorker' in navigator) {
      const regs = await navigator.serviceWorker.getRegistrations();
      await Promise.all(regs.map((reg) => reg.unregister()));
    }
    if ('caches' in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }

    localStorage.clear();
    sessionStorage.clear();
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
  });
  await page.reload();
}

export function imageUploadInput(page: Page) {
  return page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
}

export async function clickStartBuildingIfVisible(page: Page, timeoutMs = 90000) {
  const startBtn = page.getByRole('button', { name: /Start Building|Close/i }).first();
  try {
    await startBtn.waitFor({ state: 'visible', timeout: Math.min(timeoutMs, 15000) });
    await startBtn.click();
  } catch {
    // Some flows auto-complete without showing the summary modal.
  }
}

export async function waitForSidebarInteractive(page: Page, timeoutMs = 90000) {
  const newButton = page.getByRole('button', { name: 'New' });
  const modalActionButton = page.getByRole('button', { name: /Start Building|Close/i }).first();
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

export async function uploadImageAndWaitForSceneCount(
  page: Page,
  imagePath: string,
  expectedSceneCount: number,
  timeoutMs = 90000,
) {
  const fileInput = imageUploadInput(page);
  await fileInput.setInputFiles([imagePath]);
  await clickStartBuildingIfVisible(page, timeoutMs);
  await waitForSidebarInteractive(page, timeoutMs);
  await expect(page.locator('.scene-item')).toHaveCount(expectedSceneCount, { timeout: timeoutMs });

  const lockOverlay = page.locator('.interaction-lock-overlay');
  if ((await lockOverlay.count()) > 0) {
    await expect(lockOverlay).not.toBeVisible({ timeout: timeoutMs });
  }
}

export async function loadProjectZipAndWait(page: Page, zipPath: string, timeoutMs = 90000) {
  const fileInput = page.locator('input[type="file"][accept*=".zip"]');
  await fileInput.setInputFiles(zipPath);
  await clickStartBuildingIfVisible(page, timeoutMs);
  await waitForSidebarInteractive(page, timeoutMs);
  await waitForNavigationStabilization(page, Math.min(timeoutMs, 30000));
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
