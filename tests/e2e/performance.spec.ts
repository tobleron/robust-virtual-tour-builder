import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

test.describe('Performance & Load Testing', () => {
    test.beforeEach(async ({ page }) => {
        await setupAIObservability(page);
        await page.goto('/');

        await page.evaluate(async () => {
            localStorage.clear();
            sessionStorage.clear();
            const dbs = await window.indexedDB.databases();
            dbs.forEach(db => { if (db.name) window.indexedDB.deleteDatabase(db.name); });
        });
        await page.reload();
    });

    test('5.1: Large project (200 scenes) responsiveness', async ({ page }) => {
        test.setTimeout(180000);

        console.log('Generating 200 scenes project...');
        await page.evaluate(() => {
            const scenes = [];
            for (let i = 0; i < 200; i++) {
                scenes.push({
                    id: `scene-${i}`,
                    name: `Scene ${i}`,
                    label: `Scene ${i}`,
                    file: 'images/image.jpg',
                    hotspots: [],
                    quality: { score: 9.0, stats: { avgLuminance: 120 } },
                    colorGroup: (i % 5).toString()
                });
            }

            const projectData = {
                id: 'perf-test-id',
                tourName: 'Performance Test Tour',
                scenes: scenes
            };

            if ((window as any).store && (window as any).store.loadProject) {
                (window as any).store.loadProject(projectData);
            } else {
                throw new Error('State Inspector is not enabled or window.store is missing');
            }
        });

        await expect(page.locator('.scene-item').first()).toBeVisible({ timeout: 30000 });

        console.log('Verifying UI responsiveness with 200 scenes...');
        const start = Date.now();
        await page.locator('.scene-item').nth(199).scrollIntoViewIfNeeded();
        const end = Date.now();

        console.log(`Scroll to item 200 took ${end - start}ms`);
        // Expect scroll to be reasonably fast
        expect(end - start).toBeLessThan(3000);

        await page.locator('.scene-item').nth(100).click();
        await expect(page.locator('.scene-item').nth(100)).toHaveClass(/active/);
    });

    test('5.2: Memory usage should remain stable', async ({ page }) => {
        test.setTimeout(180000);

        await page.evaluate(() => {
            const scenes = [];
            for (let i = 0; i < 50; i++) {
                scenes.push({
                    id: `scene-${i}`,
                    name: `Scene ${i}`,
                    label: `Scene ${i}`,
                    file: 'images/image.jpg',
                    hotspots: [],
                    quality: { score: 9.0, stats: { avgLuminance: 120 } },
                    colorGroup: '1'
                });
            }
            (window as any).store.loadProject({ id: 'mem-test', tourName: 'Memory Test', scenes });
        });

        await expect(page.locator('.scene-item').first()).toBeVisible();

        const getMemory = async () => {
            return await page.evaluate(() => {
                return (performance as any).memory ? (performance as any).memory.usedJSHeapSize : 0;
            });
        };

        const memInitial = await getMemory();
        console.log(`Initial memory: ${memInitial}`);

        for (let i = 0; i < 10; i++) {
            await page.locator('.scene-item').nth(i * 5).click();
            await page.waitForTimeout(200);
        }

        const memFinal = await getMemory();
        console.log(`Final memory after navigation: ${memFinal}`);

        if (memInitial > 0) {
            // Allow for reasonable growth
            expect(memFinal / memInitial).toBeLessThan(4);
        }
    });

    test('5.3: Bundle size validation', async ({ page }) => {
        const responses = [];
        page.on('response', response => {
            responses.push(response);
        });

        await page.reload();

        let totalJSSize = 0;
        for (const response of responses) {
            const url = response.url();
            const headers = response.headers();
            if (url.endsWith('.js') && !url.includes('hot-update')) {
                const contentLength = headers['content-length'];
                if (contentLength) {
                    totalJSSize += parseInt(contentLength, 10);
                }
            }
        }

        console.log(`Total JS downloaded: ${Math.round(totalJSSize / 1024)} KB`);
        // Budget limit
        expect(totalJSSize / 1024).toBeLessThan(2000);
    });
});
