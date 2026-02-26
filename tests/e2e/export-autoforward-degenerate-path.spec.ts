import { test, expect } from '@playwright/test';
import { generateTourHTML } from '../../src/systems/TourTemplates.bs.js';

test.describe('Export Auto-Forward Degenerate Path', () => {
  test('@budget should still schedule auto-forward when waypoint path is degenerate', async ({ page }) => {
    const scenes = [
      {
        id: 's1',
        name: 'Scene-1.jpg',
        file: 'Scene-1.jpg',
        floor: 'g',
        hotspots: [
          {
            pitch: 0,
            yaw: 0,
            target: 's2',
            targetSceneId: 's2',
            isAutoForward: true,
          },
        ],
      },
      {
        id: 's2',
        name: 'Scene-2.jpg',
        file: 'Scene-2.jpg',
        floor: '1',
        hotspots: [],
      },
    ];
    const html = generateTourHTML(scenes, 'Degenerate AF', undefined, 'hd', 32, 40, '1.0');

    // Prevent runtime crash when exported HTML expects pannellum from external script.
    await page.addInitScript(() => {
      (window as any).pannellum = {
        viewer: () => ({
          on: () => undefined,
          getScene: () => 's1',
          getPitch: () => 0,
          getYaw: () => 0,
          lookAt: () => undefined,
          loadScene: () => undefined,
        }),
      };
    });

    await page.setContent(html, { waitUntil: 'load' });
    await page.waitForFunction(() => typeof (window as any).animateSceneToPrimaryHotspot === 'function');

    const scheduled = await page.evaluate(() => {
      let timeoutCount = 0;
      const originalSetTimeout = window.setTimeout.bind(window);
      (window as any).setTimeout = ((handler: TimerHandler, timeout?: number, ...args: any[]) => {
        if (timeout === 360) timeoutCount += 1;
        return originalSetTimeout(handler, timeout, ...args);
      }) as typeof window.setTimeout;

      // Force minimal deterministic environment.
      (window as any).viewer = {
        getScene: () => 's1',
        getPitch: () => 0,
        getYaw: () => 0,
        lookAt: () => undefined,
        loadScene: () => undefined,
      };
      (window as any).setSceneHotspotsPending = () => undefined;
      (window as any).setSceneHotspotsReadyWithRetry = () => undefined;
      (window as any).updateLookingModeUI = () => undefined;
      (window as any).resetAutoForwardLoopGuard = () => undefined;
      (window as any).attemptAutoForwardNavigation = () => undefined;
      (window as any).resolveScenePlaybackHotspot = () => ({
        hotspot: {
          pitch: 1,
          yaw: 2,
          targetYaw: null,
          targetPitch: null,
          viewFrame: null,
          truePitch: 1,
          waypoints: [],
          startYaw: null,
          startPitch: null,
        },
        hotspotIndex: 0,
        autoForward: true,
        targetSceneId: 's2',
      });
      (window as any).buildPath = () => [{ yaw: 0, pitch: 0 }];

      // Ensure scene exists for the runtime lookup.
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (scenesData as any).s1 = { hotSpots: [{}], autoForwardHotspotIndex: 0 };

      (window as any).isAutoTourActive = false;
      (window as any).animateSceneToPrimaryHotspot('s1', 20);
      return timeoutCount;
    });

    expect(scheduled).toBeGreaterThan(0);
  });

  test('@budget should land into auto-forward scene at that scene terminal endpoint', async ({ page }) => {
    const scenes = [
      {
        id: 's1',
        name: 'Scene-1.jpg',
        file: 'Scene-1.jpg',
        floor: 'g',
        hotspots: [
          {
            pitch: 0,
            yaw: 0,
            target: 's2',
            targetSceneId: 's2',
            isAutoForward: false,
            targetYaw: 10,
            targetPitch: 5,
          },
        ],
      },
      {
        id: 's2',
        name: 'Scene-2.jpg',
        file: 'Scene-2.jpg',
        floor: '1',
        hotspots: [
          {
            pitch: 1,
            yaw: 2,
            target: 's3',
            targetSceneId: 's3',
            isAutoForward: true,
            viewFrame: { yaw: 120, pitch: -10 },
            targetYaw: 120,
            targetPitch: -10,
          },
        ],
      },
      {
        id: 's3',
        name: 'Scene-3.jpg',
        file: 'Scene-3.jpg',
        floor: '2',
        hotspots: [],
      },
    ];
    const html = generateTourHTML(scenes, 'AF arrival endpoint', undefined, 'hd', 32, 40, '1.0');

    await page.addInitScript(() => {
      (window as any).pannellum = {
        viewer: () => ({
          on: () => undefined,
          getScene: () => 's1',
          getPitch: () => 0,
          getYaw: () => 0,
          lookAt: () => undefined,
          loadScene: () => undefined,
        }),
      };
    });

    await page.setContent(html, { waitUntil: 'load' });
    await page.waitForFunction(() => typeof (window as any).navigateToNextScene === 'function');

    const arrival = await page.evaluate(() => {
      let captured: { sceneId: string; pitch: number; yaw: number } | null = null;

      (window as any).viewer = {
        getScene: () => 's1',
        getPitch: () => 0,
        getYaw: () => 0,
        lookAt: () => undefined,
        loadScene: (sceneId: string, pitch: number, yaw: number) => {
          captured = { sceneId, pitch, yaw };
        },
      };

      // Execute transition timeout immediately.
      (window as any).setTimeout = ((handler: TimerHandler) => {
        if (typeof handler === 'function') handler();
        return 1 as unknown as number;
      }) as typeof window.setTimeout;

      (window as any).navigateToNextScene(
        {
          sourceSceneId: 's1',
          targetSceneId: 's2',
          target: 's2',
          targetYaw: 10,
          targetPitch: 5,
        },
        's2',
        {},
      );

      return captured;
    });

    expect(arrival).not.toBeNull();
    expect(arrival?.sceneId).toBe('s2');
    expect(arrival?.yaw).toBe(120);
    expect(arrival?.pitch).toBe(-10);
  });
});
