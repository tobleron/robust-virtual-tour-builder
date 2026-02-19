import { expect, Page } from '@playwright/test';

export async function resetClientState(page: Page) {
  await page.goto('/');
  await page.evaluate(async () => {
    localStorage.clear();
    sessionStorage.clear();
    const dbs = await window.indexedDB.databases();
    dbs.forEach((db) => {
      if (db.name) {
        window.indexedDB.deleteDatabase(db.name);
      }
    });
  });
  await page.reload();
}

export function imageUploadInput(page: Page) {
  return page.locator('input[type="file"][accept="image/jpeg,image/png,image/webp"]');
}

export async function clickStartBuildingIfVisible(page: Page, timeoutMs = 90000) {
  const startBtn = page.getByRole('button', { name: /Start Building/i });
  try {
    await startBtn.waitFor({ state: 'visible', timeout: timeoutMs });
    await startBtn.click();
  } catch {
    // Some flows auto-complete without showing the summary modal.
  }
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
  await expect(page.locator('.scene-item')).toHaveCount(expectedSceneCount, { timeout: timeoutMs });

  const lockOverlay = page.locator('.interaction-lock-overlay');
  if ((await lockOverlay.count()) > 0) {
    await expect(lockOverlay).not.toBeVisible({ timeout: timeoutMs });
  }
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
