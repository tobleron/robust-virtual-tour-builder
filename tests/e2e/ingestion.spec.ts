import { test, expect } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { loadProjectZipAndWait, resetClientState, uploadImageAndWaitForSceneCount, setupAuthentication } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const ZIP_PATH = path.resolve(process.cwd(), 'artifacts/layan_complete_tour.zip');
const IMAGE_PATH = path.join(FIXTURES_DIR, 'image.jpg');

test.describe('Ingestion Pipeline', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await setupAuthentication(page, 'dev-token');
    await resetClientState(page, { authToken: 'dev-token' });
  });

  test('should upload layan_complete_tour.zip and load the project', async ({ page }) => {
    await loadProjectZipAndWait(page, ZIP_PATH, 30000);

    await expect(page.locator('.scene-item')).toHaveCount(29, { timeout: 30000 });
    await expect(page.locator('input[placeholder="New Tour..."]')).toHaveValue(/Layan/i, { timeout: 10000 });
  });

  test('should upload images and create new scenes', async ({ page }) => {
    await uploadImageAndWaitForSceneCount(page, IMAGE_PATH, 1, 30000);
  });
});
