import { beforeEach, describe, expect, test, vi } from 'vitest';

describe('TeaserManagerLogic wiring', () => {
  beforeEach(() => {
    vi.resetModules();
  });

  test('forwards style and pan-speed arguments into headless teaser logic', async () => {
    const headlessMock = {
      startHeadlessTeaserWithStyle: vi.fn().mockResolvedValue(undefined),
    };

    vi.doMock('../../src/systems/TeaserHeadlessLogic.bs.js', () => headlessMock);

    const mod = await import('../../src/systems/TeaserManagerLogic.bs.js');
    const getState = vi.fn();
    const dispatch = vi.fn();
    const signal = { aborted: false };
    const onCancel = vi.fn();

    await mod.Manager.startHeadlessTeaserWithStyle(
      'webm',
      'cinematic',
      'fast',
      getState,
      dispatch,
      signal,
      onCancel
    );

    expect(headlessMock.startHeadlessTeaserWithStyle).toHaveBeenCalledTimes(1);
    const args = headlessMock.startHeadlessTeaserWithStyle.mock.calls[0];
    expect(typeof args[0]).toBe('function');
    expect(args.slice(1)).toEqual(['webm', 'cinematic', 'fast', getState, dispatch, signal, onCancel]);
  });
});

describe('Teaser facade wiring', () => {
  beforeEach(() => {
    vi.resetModules();
  });

  test('startHeadlessTeaserWithStyle forwards style and pan-speed to the manager facade', async () => {
    const managerMock = {
      Manager: {
        startAutoTeaser: vi.fn(),
        startCinematicTeaser: vi.fn(),
        startHeadlessTeaser: vi.fn(),
        startHeadlessTeaserWithStyle: vi.fn().mockResolvedValue(undefined),
      },
    };

    vi.doMock('../../src/systems/TeaserManagerLogic.bs.js', () => managerMock);
    vi.doMock('../../src/systems/TeaserLogic.bs.js', () => ({
      Recorder: {},
      Pathfinder: {},
      Server: {},
      State: {},
      Playback: {},
      Manager: {},
      readHeadlessMotionProfile: vi.fn(),
      readMotionManifest: vi.fn(),
      resolveTeaserStartView: vi.fn(),
      centerViewerAtWaypointStart: vi.fn(),
      startHeadlessTeaserForWindow: vi.fn(),
      startCinematicTeaserForWindow: vi.fn(),
      isAutoPilotActiveForWindow: vi.fn(),
    }));

    const mod = await import('../../src/systems/Teaser.bs.js');
    const getState = vi.fn();
    const dispatch = vi.fn();
    const signal = { aborted: false };
    const onCancel = vi.fn();

    await mod.startHeadlessTeaserWithStyle(
      'webm',
      'cinematic',
      'fast',
      getState,
      dispatch,
      signal,
      onCancel
    );

    expect(managerMock.Manager.startHeadlessTeaserWithStyle).toHaveBeenCalledWith(
      'webm',
      'cinematic',
      'fast',
      getState,
      dispatch,
      signal,
      onCancel
    );
  });
});
