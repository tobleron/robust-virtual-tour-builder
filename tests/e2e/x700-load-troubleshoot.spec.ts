import { test, expect } from '@playwright/test';
import path from 'node:path';
import fs from 'node:fs';

const ZIP_PATH = path.resolve(process.cwd(), 'artifacts/x700.zip');

async function hardReset(page: any) {
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
  await page.waitForLoadState('networkidle');
}

test.describe('Troubleshoot x700 project load', () => {
  test('simulates loading artifacts/x700.zip and captures behavior', async ({ page }) => {
    test.setTimeout(900000);

    if (!fs.existsSync(ZIP_PATH)) {
      throw new Error(`Missing test artifact: ${ZIP_PATH}`);
    }

    const consoleErrors: string[] = [];
    const consoleWarnings: string[] = [];
    const failedResponses: Array<{ status: number; url: string }> = [];

    page.on('console', (msg) => {
      const txt = msg.text();
      if (msg.type() === 'error') {
        consoleErrors.push(txt);
      } else if (msg.type() === 'warning') {
        consoleWarnings.push(txt);
      }
    });

    page.on('response', (res) => {
      if (res.status() >= 400) {
        const url = res.url();
        if (
          url.includes('/api/project/') ||
          url.includes('/api/media/') ||
          url.includes('/file/thumb-')
        ) {
          failedResponses.push({ status: res.status(), url });
        }
      }
    });

    await hardReset(page);

    const loadStart = Date.now();
    let processingBarVisible = false;

    const statusBar = page.locator('[role="status"]');
    const loadInput = page.locator('input[type="file"][accept*=".zip"]');

    if ((await loadInput.count()) > 0) {
      await loadInput.first().setInputFiles([ZIP_PATH]);
    } else {
      const loadBtn = page.getByLabel('Load');
      const chooserPromise = page.waitForEvent('filechooser');
      await loadBtn.click();
      const chooser = await chooserPromise;
      await chooser.setFiles([ZIP_PATH]);
    }

    try {
      await expect(statusBar).toBeVisible({ timeout: 20000 });
      processingBarVisible = true;
    } catch {
      processingBarVisible = false;
    }

    // Wait until project scenes hydrate into canonical sceneOrder state.
    await page.waitForFunction(
      () => {
        const w = window as any;
        const s = w.store?.getFullState?.() ?? w.store?.state;
        return !!s && Array.isArray(s.sceneOrder) && s.sceneOrder.length >= 70;
      },
      undefined,
      { timeout: 600000 },
    );

    // Wait for ProjectLoading mode to clear.
    await page.waitForFunction(
      () => {
        const w = window as any;
        const s = w.store?.getFullState?.() ?? w.store?.state;
        const mode = s?.appMode;
        if (!mode) return false;
        if (typeof mode === 'string') return !mode.includes('ProjectLoading');
        const tag = mode.TAG;
        if (tag !== 1) return true; // not SystemBlocking
        const payload = mode._0;
        if (!payload) return true;
        const innerTag = payload.TAG;
        return innerTag !== 1; // not ProjectLoading
      },
      undefined,
      { timeout: 600000 },
    );

    const loadDurationMs = Date.now() - loadStart;

    const stateSummary = await page.evaluate(() => {
      const w = window as any;
      const s = w.store?.getFullState?.() ?? w.store?.state;
      return {
        sceneCount: Array.isArray(s?.scenes) ? s.scenes.length : -1,
        sceneOrderCount: Array.isArray(s?.sceneOrder) ? s.sceneOrder.length : -1,
        hasSessionId: !!s?.sessionId,
        appModeTag: s?.appMode?.TAG,
      };
    });

    const thumb404s = failedResponses.filter(
      (r) => r.status === 404 && r.url.includes('/file/thumb-'),
    );

    console.log('[x700] loadDurationMs=', loadDurationMs);
    console.log('[x700] processingBarVisible=', processingBarVisible);
    console.log('[x700] stateSummary=', JSON.stringify(stateSummary));
    console.log('[x700] failedResponses=', failedResponses.length);
    console.log('[x700] thumb404s=', thumb404s.length);
    console.log('[x700] consoleErrors=', consoleErrors.length);
    console.log('[x700] consoleWarnings=', consoleWarnings.length);

    expect(stateSummary.sceneOrderCount).toBeGreaterThanOrEqual(70);
    expect(stateSummary.hasSessionId).toBeTruthy();
    expect(thumb404s.length).toBe(0);
  });
});
