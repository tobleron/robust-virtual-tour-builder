import { test, expect, type Page } from '@playwright/test';
import path from 'path';
import { fileURLToPath } from 'url';
import { setupAIObservability } from './ai-helper';
import { loadProjectZipAndWait, resetClientState, setupAuthentication } from './e2e-helpers';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const FIXTURES_DIR = path.join(__dirname, 'fixtures');
const LINKED_TOUR_ZIP_PATH = path.join(FIXTURES_DIR, 'tour_linked.vt.zip');

test.describe('Hotspot labels and sidebar spinner guardrails', () => {
  test.beforeEach(async ({ page }) => {
    await setupAIObservability(page);
    await setupAuthentication(page, 'dev-token');
    await resetClientState(page, { authToken: 'dev-token' });
  });

  async function loadLinkedTour(page: Page) {
    await loadProjectZipAndWait(page, LINKED_TOUR_ZIP_PATH, 90000);
    await expect(page.locator('.scene-item')).toHaveCount(2, { timeout: 30000 });
  }

  test('renders persistent hotspot destination label and keeps spinner off sidebar buttons', async ({ page }) => {
    await loadLinkedTour(page);

    const hotspot = page.locator('#hs-react-link-1');
    const label = page.locator('#react-hotspot-layer .hs-hotspot-label').first();

    await expect(hotspot).toBeVisible({ timeout: 15000 });
    await expect(label).toBeVisible({ timeout: 15000 });
    await expect(label).toHaveText(/Scene 2/);
    await expect(label).not.toHaveText(/^#/);

    const [labelBox, hotspotBox] = await Promise.all([label.boundingBox(), hotspot.boundingBox()]);
    expect(labelBox).not.toBeNull();
    expect(hotspotBox).not.toBeNull();
    expect((labelBox as NonNullable<typeof labelBox>).y + (labelBox as NonNullable<typeof labelBox>).height).toBeLessThanOrEqual(
      (hotspotBox as NonNullable<typeof hotspotBox>).y,
    );

    const style = await label.evaluate((el) => {
      const computed = window.getComputedStyle(el);
      return {
        zIndex: computed.zIndex,
        fontSize: computed.fontSize,
        color: computed.color,
      };
    });
    expect(style.zIndex).toBe('6100');
    expect(style.fontSize).toBe('13px');
    expect(style.color).toBe('rgb(255, 255, 255)');
    await page.getByRole('button', { name: 'Save' }).click();

    await expect(
      page.locator('.sidebar-action-btn-square.btn-loading, .sidebar-action-btn-wide.btn-loading'),
    ).toHaveCount(0);
    await expect(page.locator('#sidebar .sidebar-action-btn-square .spinner')).toHaveCount(0);
    await expect(page.locator('#sidebar .sidebar-action-btn-wide .spinner')).toHaveCount(0);
  });
});
