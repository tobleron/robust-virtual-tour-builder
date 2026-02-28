import { test, expect } from '@playwright/test';
import path from 'node:path';
import fs from 'node:fs';
import { clickStartBuildingIfVisible, resetClientState, waitForNavigationStabilization } from './e2e-helpers';

const TEST_ZIP = path.resolve(process.cwd(), 'artifacts/test.zip');

type CursorProbe = {
  hasHotspotRoot: boolean;
  hasClickable: boolean;
  clickableCursor: string | null;
  clickablePointerEvents: string | null;
  topTag: string | null;
  topId: string | null;
  topClass: string | null;
  topCursor: string | null;
  topPointerEvents: string | null;
  navBusy: boolean | null;
  pipelineContainerPointerEvents: string | null;
  pipelineWrapperPointerEvents: string | null;
};

let probeCursor = (): CursorProbe => {
  const root = document.querySelector<HTMLElement>('#react-hotspot-layer [id^="hs-react-"]');
  const pipelineContainer = document.getElementById('visual-pipeline-container') as HTMLElement | null;
  const pipelineWrapper = document.querySelector<HTMLElement>('.visual-pipeline-wrapper');
  const clickable = root?.querySelector<HTMLElement>('.cursor-pointer');
  if (!root || !clickable) {
    return {
      hasHotspotRoot: !!root,
      hasClickable: !!clickable,
      clickableCursor: null,
      clickablePointerEvents: null,
      topTag: null,
      topId: null,
      topClass: null,
      topCursor: null,
      topPointerEvents: null,
      navBusy: (window as any).OperationLifecycle?.isBusy?.({ type: 'Navigation' }) ?? null,
      pipelineContainerPointerEvents: pipelineContainer ? getComputedStyle(pipelineContainer).pointerEvents : null,
      pipelineWrapperPointerEvents: pipelineWrapper ? getComputedStyle(pipelineWrapper).pointerEvents : null,
    };
  }

  const rect = clickable.getBoundingClientRect();
  const x = Math.round(rect.left + rect.width / 2);
  const y = Math.round(rect.top + rect.height / 2);
  const top = document.elementFromPoint(x, y) as HTMLElement | null;
  const clickableStyle = getComputedStyle(clickable);

  return {
    hasHotspotRoot: true,
    hasClickable: true,
    clickableCursor: clickableStyle.cursor,
    clickablePointerEvents: clickableStyle.pointerEvents,
    topTag: top?.tagName ?? null,
    topId: top?.id ?? null,
    topClass: top?.className ?? null,
    topCursor: top ? getComputedStyle(top).cursor : null,
    topPointerEvents: top ? getComputedStyle(top).pointerEvents : null,
    navBusy: (window as any).OperationLifecycle?.isBusy?.({ type: 'Navigation' }) ?? null,
    pipelineContainerPointerEvents: pipelineContainer ? getComputedStyle(pipelineContainer).pointerEvents : null,
    pipelineWrapperPointerEvents: pipelineWrapper ? getComputedStyle(pipelineWrapper).pointerEvents : null,
  };
};

test.describe('edge case: first scene waypoint cursor unlock (test.zip)', () => {
  test('captures cursor state before vs after drag on first scene flow', async ({ page }) => {
    test.setTimeout(180000);
    if (!fs.existsSync(TEST_ZIP)) {
      throw new Error(`Required fixture missing: ${TEST_ZIP}`);
    }

    await resetClientState(page);
    await page.goto('/');

    await page.locator('#sidebar-project-upload').setInputFiles([TEST_ZIP]);
    await clickStartBuildingIfVisible(page, 90000);

    await page.waitForFunction(
      () => {
        const count = document.querySelectorAll('.scene-item').length;
        return count > 0;
      },
      undefined,
      { timeout: 120000 },
    );

    await waitForNavigationStabilization(page, 45000);

    // Use first waypoint arrow in first scene (edge case scope).
    const firstArrow = page.locator('#viewer-hotspot-lines [id^="arrow_"]').first();
    await expect(firstArrow).toBeVisible({ timeout: 45000 });
    const clicked = await page.evaluate(() => {
      const arrow = document.querySelector<SVGElement>('#viewer-hotspot-lines [id^="arrow_"]');
      if (!arrow) {
        return false;
      }
      arrow.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, composed: true }));
      return true;
    });
    expect(clicked).toBeTruthy();

    await waitForNavigationStabilization(page, 45000);
    await page.waitForTimeout(1000);

    const beforeDrag = await page.evaluate(probeCursor);

    const box = await page.locator('#viewer-stage').boundingBox();
    if (box) {
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
      await page.mouse.down();
      await page.mouse.move(box.x + box.width / 2 + 30, box.y + box.height / 2 + 10);
      await page.mouse.up();
      await page.waitForTimeout(350);
    }

    const afterDrag = await page.evaluate(probeCursor);

    // Diagnostic trace in test output for root-cause analysis/rollback decisions.
    // eslint-disable-next-line no-console
    console.log('TEST_ZIP_CURSOR_PROBE_BEFORE_DRAG', JSON.stringify(beforeDrag));
    // eslint-disable-next-line no-console
    console.log('TEST_ZIP_CURSOR_PROBE_AFTER_DRAG', JSON.stringify(afterDrag));

    expect(beforeDrag.hasHotspotRoot).toBeTruthy();
    expect(beforeDrag.hasClickable).toBeTruthy();
    expect(beforeDrag.pipelineContainerPointerEvents).toBe("none");
    expect(beforeDrag.pipelineWrapperPointerEvents).toBe("none");
  });
});
