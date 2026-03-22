import { test, expect } from '@playwright/test';
import path from 'node:path';
import fs from 'node:fs';
import { setupAuthentication } from './ai-helper';

const ZIP_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

async function hardReset(page: any) {
  await setupAuthentication(page, 'dev-token');
  await page.goto('/builder');
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
  await page.waitForLoadState('networkidle');
}

test.describe('Troubleshoot x700 project load', () => {
  test('simulates loading artifacts/layan_complete_tour.zip and captures behavior', async ({ page }) => {
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
        return !!s && Array.isArray(s.sceneOrder) && s.sceneOrder.length >= 20;
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


    expect(stateSummary.sceneOrderCount).toBeGreaterThanOrEqual(20);
    expect(stateSummary.hasSessionId).toBeTruthy();
    expect(thumb404s.length).toBe(0);
  });
});
