import { test, expect, Page } from '@playwright/test';
import path from 'path';
import { setupAIObservability } from './ai-helper';

const fixturePath = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

async function resetAndOpen(page: Page) {
  await setupAIObservability(page);
  await page.goto('/');
  await page.evaluate(async () => {
    localStorage.clear();
    sessionStorage.clear();
    const dbs = await window.indexedDB.databases();
    dbs.forEach(db => {
      if (db.name) window.indexedDB.deleteDatabase(db.name);
    });
  });
  await page.reload();
}

async function triggerImport(page: Page) {
  const fileInput = page.locator('input[type="file"][accept*=".zip"]');
  await fileInput.setInputFiles(fixturePath);
  const startBtn = page.getByRole('button', { name: /Start Building|Close/i }).first();
  try {
    await expect(startBtn).toBeVisible({ timeout: 15000 });
    await startBtn.click();
  } catch {
    // Import may complete without showing summary modal.
  }
}

function successImportResponse(sceneCount = 2) {
  return {
    sessionId: 'chunked-import-session',
    projectData: {
      scenes: Array.from({ length: sceneCount }, (_, i) => ({
        id: `scene_${i}`,
        name: `Scene ${i}`,
        fileName: `image_${i}.jpg`,
        url: 'blob:test',
        fov: 100,
        links: [],
        quality: null,
      })),
      version: 1,
    },
  };
}

test.describe('Chunked Import', () => {
  test('happy path completes chunked import', async ({ page }) => {
    let initCalled = 0;
    let chunkCalled = 0;
    let completeCalled = 0;

    await page.route('**/api/project/import/init', async route => {
      initCalled += 1;
      await route.fulfill({
        status: 200,
        json: {
          uploadId: 'up-1',
          chunkSizeBytes: 1024 * 1024,
          totalChunks: 1,
          expiresAtEpochMs: Date.now() + 3600000,
        },
      });
    });
    await page.route('**/api/project/import/status/**', async route => {
      await route.fulfill({
        status: 200,
        json: { receivedChunks: [], nextExpectedChunk: 0, totalChunks: 1, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/chunk', async route => {
      chunkCalled += 1;
      await route.fulfill({ status: 200, json: { accepted: true, nextExpectedChunk: 1, receivedCount: 1 } });
    });
    await page.route('**/api/project/import/complete', async route => {
      completeCalled += 1;
      await route.fulfill({ status: 200, json: successImportResponse(2) });
    });
    await page.route('**/api/project/*/file/**', async route => {
      const gif = Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64');
      await route.fulfill({ status: 200, contentType: 'image/gif', body: gif });
    });
    await page.route('**/api/telemetry/**', async route => route.fulfill({ status: 200 }));

    await resetAndOpen(page);
    await triggerImport(page);

    await expect(page.locator('.scene-item')).toHaveCount(2, { timeout: 20000 });
    expect(initCalled).toBe(1);
    expect(chunkCalled).toBe(1);
    expect(completeCalled).toBe(1);
  });

  test('resume uploads only missing chunks after interruption', async ({ page }) => {
    let chunkBodies: string[] = [];
    await page.route('**/api/project/import/init', async route => {
      await route.fulfill({
        status: 200,
        json: { uploadId: 'up-resume', chunkSizeBytes: 16, totalChunks: 2, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/status/**', async route => {
      await route.fulfill({
        status: 200,
        json: { receivedChunks: [0], nextExpectedChunk: 1, totalChunks: 2, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/chunk', async route => {
      const body = route.request().postData() || '';
      chunkBodies.push(body);
      await route.fulfill({ status: 200, json: { accepted: true, nextExpectedChunk: 2, receivedCount: 2 } });
    });
    await page.route('**/api/project/import/complete', async route => {
      await route.fulfill({ status: 200, json: successImportResponse(2) });
    });
    await page.route('**/api/project/*/file/**', async route => {
      const gif = Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64');
      await route.fulfill({ status: 200, contentType: 'image/gif', body: gif });
    });
    await page.route('**/api/telemetry/**', async route => route.fulfill({ status: 200 }));

    await resetAndOpen(page);
    await triggerImport(page);
    await expect(page.locator('.scene-item')).toHaveCount(2, { timeout: 20000 });

    expect(chunkBodies.length).toBe(1);
    expect(chunkBodies[0]).toContain('name="chunkIndex"');
    expect(chunkBodies[0]).toContain('\r\n1\r\n');
  });

  test('handles 429 backoff during chunk upload and recovers', async ({ page }) => {
    let chunkAttempt = 0;
    await page.route('**/api/project/import/init', async route => {
      await route.fulfill({
        status: 200,
        json: { uploadId: 'up-429', chunkSizeBytes: 1024 * 1024, totalChunks: 1, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/status/**', async route => {
      await route.fulfill({
        status: 200,
        json: { receivedChunks: [], nextExpectedChunk: 0, totalChunks: 1, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/chunk', async route => {
      chunkAttempt += 1;
      if (chunkAttempt === 1) {
        await route.fulfill({
          status: 429,
          headers: { 'retry-after': '1', 'x-ratelimit-after': '1' },
          json: { message: 'rate limited', retryAfterSec: 1 },
        });
      } else {
        await route.fulfill({ status: 200, json: { accepted: true, nextExpectedChunk: 1, receivedCount: 1 } });
      }
    });
    await page.route('**/api/project/import/complete', async route => {
      await route.fulfill({ status: 200, json: successImportResponse(2) });
    });
    await page.route('**/api/project/*/file/**', async route => {
      const gif = Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64');
      await route.fulfill({ status: 200, contentType: 'image/gif', body: gif });
    });
    await page.route('**/api/telemetry/**', async route => route.fulfill({ status: 200 }));

    await resetAndOpen(page);
    await triggerImport(page);
    await expect(page.locator('.scene-item')).toHaveCount(2, { timeout: 30000 });
    expect(chunkAttempt).toBeGreaterThan(1);
  });

  test('aborts chunked import session when upload fails', async ({ page }) => {
    let abortCalled = 0;
    await page.route('**/api/project/import/init', async route => {
      await route.fulfill({
        status: 200,
        json: { uploadId: 'up-abort', chunkSizeBytes: 1024 * 1024, totalChunks: 1, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/status/**', async route => {
      await route.fulfill({
        status: 200,
        json: { receivedChunks: [], nextExpectedChunk: 0, totalChunks: 1, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/chunk', async route => {
      await route.fulfill({ status: 500, json: { message: 'chunk failed' } });
    });
    await page.route('**/api/project/import/abort', async route => {
      abortCalled += 1;
      await route.fulfill({ status: 200, json: { aborted: true } });
    });
    await page.route('**/api/telemetry/**', async route => route.fulfill({ status: 200 }));

    await resetAndOpen(page);
    await triggerImport(page);
    await expect(page.locator('.scene-item')).toHaveCount(0, { timeout: 10000 });
    expect(abortCalled).toBe(1);
  });

  test('fails safely on expired or invalid upload session', async ({ page }) => {
    await page.route('**/api/project/import/init', async route => {
      await route.fulfill({
        status: 200,
        json: { uploadId: 'up-expired', chunkSizeBytes: 1024 * 1024, totalChunks: 1, expiresAtEpochMs: Date.now() - 1000 },
      });
    });
    await page.route('**/api/project/import/status/**', async route => {
      await route.fulfill({ status: 404, json: { message: 'invalid upload id' } });
    });
    await page.route('**/api/project/import/chunk', async route => {
      await route.fulfill({ status: 404, json: { message: 'session expired' } });
    });
    await page.route('**/api/project/import/abort', async route => {
      await route.fulfill({ status: 200, json: { aborted: true } });
    });
    await page.route('**/api/telemetry/**', async route => route.fulfill({ status: 200 }));

    await resetAndOpen(page);
    await triggerImport(page);
    await expect(page.locator('#viewer-stage')).toBeVisible({ timeout: 10000 });
    await expect(page.locator('.scene-item')).toHaveCount(0);
  });

  test('fails completion on metadata mismatch and keeps app stable', async ({ page }) => {
    await page.route('**/api/project/import/init', async route => {
      await route.fulfill({
        status: 200,
        json: { uploadId: 'up-mismatch', chunkSizeBytes: 1024 * 1024, totalChunks: 1, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/status/**', async route => {
      await route.fulfill({
        status: 200,
        json: { receivedChunks: [], nextExpectedChunk: 0, totalChunks: 1, expiresAtEpochMs: Date.now() + 3600000 },
      });
    });
    await page.route('**/api/project/import/chunk', async route => {
      await route.fulfill({ status: 200, json: { accepted: true, nextExpectedChunk: 1, receivedCount: 1 } });
    });
    await page.route('**/api/project/import/complete', async route => {
      await route.fulfill({ status: 400, json: { message: 'metadata mismatch' } });
    });
    await page.route('**/api/telemetry/**', async route => route.fulfill({ status: 200 }));

    await resetAndOpen(page);
    await triggerImport(page);
    await expect(page.locator('#viewer-stage')).toBeVisible({ timeout: 10000 });
    await expect(page.locator('.scene-item')).toHaveCount(0);
  });
});
