import { test, expect } from '@playwright/test';
import path from 'path';
import { setupAIObservability, setupAuthentication } from './ai-helper';
import { loadProjectZipAndWait } from './e2e-helpers';

test.describe('Race Reliability Certification (Task 1504)', () => {
    const fixturePath = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');

    test.beforeEach(async ({ page }) => {
        await setupAuthentication(page, 'dev-token');
        // 1. Mock Backend with Latency (Chunked Import Flow)
        await page.route('**/api/project/import/init', async route => {
            await route.fulfill({
                status: 200, json: {
                    uploadId: "cert-upload-id",
                    chunkSizeBytes: 1024 * 1024,
                    totalChunks: 1,
                    expiresAtEpochMs: Date.now() + 3600000
                }
            });
        });

        await page.route('**/api/project/import/status/**', async route => {
            await route.fulfill({
                status: 200, json: {
                    receivedChunks: [],
                    nextExpectedChunk: 0,
                    totalChunks: 1,
                    expiresAtEpochMs: Date.now() + 3600000
                }
            });
        });

        await page.route('**/api/project/import/chunk', async route => {
            await route.fulfill({
                status: 200, json: {
                    accepted: true,
                    nextExpectedChunk: 1,
                    receivedCount: 1
                }
            });
        });

        await page.route('**/api/project/import/complete', async route => {
            const jsonResponse = {
                sessionId: "cert-session-id",
                projectData: {
                    scenes: Array.from({ length: 10 }, (_, i) => ({
                        id: `scene_${i}`,
                        name: `Scene ${i}`,
                        fileName: `image_${i}.jpg`,
                        url: "blob:test",
                        fov: 100,
                        links: [],
                        quality: null
                    })),
                    version: 1
                }
            };
            await route.fulfill({ status: 200, json: jsonResponse });
        });

        await page.route('**/api/project/*/file/**', async route => {
            await new Promise(resolve => setTimeout(resolve, 100)); // Network delay
            const buffer = Buffer.from('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7', 'base64');
            await route.fulfill({ status: 200, contentType: 'image/gif', body: buffer });
        });

        await page.route('**/api/telemetry/**', async route => {
            await route.fulfill({ status: 200 });
        });

        await setupAIObservability(page);
        await page.goto('/');
        await page.evaluate(() => (window as any).debug?.enable());

        // 2. Initial Load
        await loadProjectZipAndWait(page, fixturePath, 60000);

        // Wait for state to reflect the 10 scenes from mock
        await expect.poll(async () => {
            const state = await page.evaluate(() => (window as any).__RE_STATE__);
            return state?.scenes?.length || 0;
        }, { timeout: 20000 }).toBe(10);

        // Wait for UI to render them
        await expect(page.locator('.scene-item')).toHaveCount(10, { timeout: 10000 });
    });

    test('Rapid Scene Interaction Stress Loop (CPU 6x)', async ({ page }) => {
        test.setTimeout(180000);
        const client = await page.context().newCDPSession(page);
        await client.send('Emulation.setCPUThrottlingRate', { rate: 6 });

        const sceneItems = page.locator('.scene-item');
        const count = await sceneItems.count();


        for (let i = 0; i < 100; i++) {
            const targetIndex = Math.floor(Math.random() * count);
            // Force click to bypass any interaction locks (we want to stress the state handling, not just the UI gating)
            await sceneItems.nth(targetIndex).click({ force: true });

            // Jitter
            if (i % 3 === 0) {
                await page.waitForTimeout(Math.random() * 20);
            }
        }


        // Wait for terminal state (Idle) using exposed OperationLifecycle
        await expect.poll(async () => {
            const isBusy = await page.evaluate(() => (window as any).OperationLifecycle?.isBusy({ type: 'Navigation' }));
            const logs = await page.evaluate(() => (window as any).__debugLogs || []);
            const lastOutcome = logs.slice().reverse().find((l: string) => l.includes('TASK_COMPLETED') || l.includes('TASK_ABORTED'));
            return isBusy === false && !!lastOutcome;
        }, { timeout: 45000 }).toBeTruthy();

        const finalLogs = await page.evaluate(() => (window as any).__debugLogs || []);
        const staleRejections = finalLogs.filter((l: string) =>
            l.includes('STALE_TASK_IGNORED') ||
            l.includes('STALE_SCENE_LOAD_IGNORED') ||
            l.includes('STALE_TASK_COMPLETION_IGNORED') ||
            l.includes('PREVIOUS_TASK_CANCELLED')
        ).length;


        // We expect SOME rejections if the race condition logic is working
        expect(staleRejections).toBeGreaterThan(0);

        await expect(page.locator('#viewer-stage')).toBeVisible();
        await expect(page.locator('text=/Something went wrong/i')).not.toBeVisible();
    });

    test('Ambient Thumbnail Generation Contention during Navigation', async ({ page }) => {
        const isAmbientBusy = await page.evaluate(() => {
            return (window as any).OperationLifecycle?.isBusy({ type: 'ThumbnailGeneration' });
        });


        const sceneItems = page.locator('.scene-item');

        for (let i = 0; i < 20; i++) {
            await sceneItems.nth(i % 5).click({ force: true });
            await page.waitForTimeout(200);
        }

        await expect.poll(async () => {
            const navBusy = await page.evaluate(() => (window as any).OperationLifecycle?.isBusy({ type: 'Navigation' }));
            return navBusy === false;
        }, { timeout: 20000 }).toBeTruthy();

        await expect(page.locator('#viewer-stage')).toBeVisible();
    });
});
