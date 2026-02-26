import { test, expect } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import { setupAIObservability } from './ai-helper';
import {
  clickStartBuildingIfVisible,
  resetClientState,
  waitForNavigationStabilization,
} from './e2e-helpers';

const ZIP_PATH = path.resolve(process.cwd(), 'artifacts/x.zip');

type OverlapProbe = {
  hasSvgOverlayOnTop: boolean;
  overlayElementId: string | null;
  arrowDisplay: string | null;
  lineDisplay: string | null;
  arrowCenterInsideMenu: boolean;
  menuButtonCount: number;
};

test.describe('T1533 hotspot overlap reproduction (x.zip)', () => {
  test('A01 menu stays above hotspot guide overlays and still navigates scene 1 -> 2', async ({
    page,
    browserName,
  }) => {
    test.skip(browserName !== 'chromium', 'Targeted troubleshooting repro runs on chromium');
    test.setTimeout(180000);

    if (!fs.existsSync(ZIP_PATH)) {
      throw new Error(`Missing required artifact: ${ZIP_PATH}`);
    }

    await setupAIObservability(page);
    await resetClientState(page);

    const loadInput = page.locator('input[type="file"][accept*=".zip"]');
    await expect(loadInput.first()).toBeAttached({ timeout: 30000 });
    await loadInput.first().setInputFiles([ZIP_PATH]);

    await clickStartBuildingIfVisible(page, 90000);

    await page.waitForFunction(
      () => {
        const w = window as any;
        const s = w.store?.getFullState?.() ?? w.store?.state;
        return !!s && Array.isArray(s.sceneOrder) && s.sceneOrder.length >= 3;
      },
      undefined,
      { timeout: 90000 },
    );

    const sceneItems = page.locator('.scene-item');
    await expect(sceneItems).toHaveCount(30, { timeout: 90000 });
    await sceneItems.nth(1).click();
    await waitForNavigationStabilization(page, 30000);

    await page.waitForFunction(
      () => {
        const w = window as any;
        const s = w.store?.getFullState?.() ?? w.store?.state;
        return s?.activeIndex === 1;
      },
      undefined,
      { timeout: 30000 },
    );

    const hotspotMainButton = page.locator('[id^="hs-react-"] .cursor-pointer').first();
    await expect(hotspotMainButton).toBeVisible({ timeout: 45000 });
    await hotspotMainButton.hover();
    await page.waitForTimeout(2000);

    const overlapProbe = await page.evaluate((): OverlapProbe => {
      const linkId = 'A01';
      const arrow = document.getElementById(`arrow_${linkId}`);
      const line = document.getElementById(`hl_${linkId}`);
      // Hotspots are now in React layer
      const hotspotRoot = document.querySelector('[id^="hs-react-"]');
      const menuButtons = Array.from(
        hotspotRoot?.querySelectorAll<HTMLElement>('.cursor-pointer') ?? [],
      ).filter((el) => {
        const rect = el.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
      });

      if (menuButtons.length === 0) {
        return {
          hasSvgOverlayOnTop: false,
          overlayElementId: null,
          arrowDisplay: arrow ? getComputedStyle(arrow).display : null,
          lineDisplay: line ? getComputedStyle(line).display : null,
          arrowCenterInsideMenu: false,
          menuButtonCount: 0,
        };
      }

      const menuUnionRect = menuButtons.reduce((acc, el) => {
        const rect = el.getBoundingClientRect();
        return {
          left: Math.min(acc.left, rect.left),
          top: Math.min(acc.top, rect.top),
          right: Math.max(acc.right, rect.right),
          bottom: Math.max(acc.bottom, rect.bottom),
        };
      }, menuButtons[0].getBoundingClientRect());

      const arrowRect = arrow?.getBoundingClientRect();
      const arrowCenterInsideMenu =
        !!arrowRect &&
        arrowRect.width > 0 &&
        arrowRect.height > 0 &&
        arrowRect.left + arrowRect.width / 2 >= menuUnionRect.left &&
        arrowRect.left + arrowRect.width / 2 <= menuUnionRect.right &&
        arrowRect.top + arrowRect.height / 2 >= menuUnionRect.top &&
        arrowRect.top + arrowRect.height / 2 <= menuUnionRect.bottom;

      // Check if SVG elements are interaction-suppressed (dimmed + pointer-events:none)
      // rather than checking elementFromPoint which ignores pointer-events
      const arrowPointerEvents = arrow ? getComputedStyle(arrow).pointerEvents : null;
      const linePointerEvents = line ? getComputedStyle(line).pointerEvents : null;
      const arrowOpacity = arrow ? parseFloat(getComputedStyle(arrow).opacity) : 1;
      const lineOpacity = line ? parseFloat(getComputedStyle(line).opacity) : 1;

      // SVG overlay is considered "on top" (interactive threat) only if it has pointer-events AND high opacity
      const svgIsInteractive =
        (arrowPointerEvents === 'auto' && arrowOpacity > 0.5 && arrowCenterInsideMenu) ||
        (linePointerEvents === 'auto' && lineOpacity > 0.5);

      return {
        hasSvgOverlayOnTop: svgIsInteractive,
        overlayElementId: svgIsInteractive ? (arrow?.id ?? line?.id ?? null) : null,
        arrowDisplay: arrow ? getComputedStyle(arrow).display : null,
        lineDisplay: line ? getComputedStyle(line).display : null,
        arrowCenterInsideMenu,
        menuButtonCount: menuButtons.length,
      };
    });

    expect(overlapProbe.menuButtonCount).toBeGreaterThanOrEqual(3);
    expect(overlapProbe.hasSvgOverlayOnTop, JSON.stringify(overlapProbe)).toBeFalsy();

    await hotspotMainButton.click();
    await waitForNavigationStabilization(page, 45000);
    await page.waitForFunction(
      () => {
        const w = window as any;
        const s = w.store?.getFullState?.() ?? w.store?.state;
        return s?.activeIndex === 2;
      },
      undefined,
      { timeout: 45000 },
    );
  });
});
