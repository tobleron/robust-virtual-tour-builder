import { beforeEach, describe, expect, test, vi } from 'vitest';

const baseState = {
  inventory: [],
  sceneOrder: ['scene-1'],
  isLinking: false,
  tourName: 'Stable Tour',
};

const baseManifest = {
  version: 'motion-spec-v1',
  fps: 60,
  canvasWidth: 1920,
  canvasHeight: 1080,
  includeIntroPan: false,
  shots: [],
};

describe('TeaserHeadlessLogic', () => {
  beforeEach(() => {
    vi.resetModules();
    vi.useRealTimers();
  });

  test('applies selected pan speed only for cinematic teaser generation', async () => {
    const fastOption = { id: 'fast', speedDegPerSec: 40, label: 'Fast', description: '40 deg/s' };
    const retimedManifest = { ...baseManifest, shots: [{ sceneId: 'scene-1' }] };
    const dispatch = vi.fn();
    const getState = vi.fn(() => baseState);
    const finalizeTeaser = vi.fn().mockResolvedValue(undefined);

    const teaserStyleConfigMock = {
      defaultPanSpeed: { id: 'standard', speedDegPerSec: 25, label: 'Standard', description: '25 deg/s' },
      resolvePanSpeedOption: vi.fn(() => fastOption),
      applyPanSpeedOption: vi.fn(() => retimedManifest),
    };
    const styleCatalogMock = {
      defaultStyle: 'Cinematic',
      fromString: vi.fn(value => (value === 'fast_shots' ? 'FastShots' : 'Cinematic')),
      isAvailable: vi.fn(() => true),
      toString: vi.fn(style => (style === 'FastShots' ? 'fast_shots' : 'cinematic')),
      label: vi.fn(style => (style === 'FastShots' ? 'Fast Shots' : 'Cinematic')),
    };
    const operationLifecycleMock = {
      start: vi.fn(() => 'op-1'),
      registerCancel: vi.fn(),
      progress: vi.fn(),
      isActive: vi.fn(() => true),
      complete: vi.fn(),
      fail: vi.fn(),
    };
    const offlineRendererMock = {
      renderWebMDeterministic: vi.fn().mockResolvedValue(true),
    };
    const renderRegistryMock = {
      buildManifestForStyle: vi.fn(() => ({ TAG: 'Ok', _0: baseManifest })),
    };

    vi.doMock('../../src/utils/Logger.bs.js', () => ({ warn: vi.fn() }));
    vi.doMock('../../src/utils/Constants.bs.js', () => ({
      Teaser: { HeadlessMotion: { skipAutoForward: false, includeIntroPan: false } },
    }));
    vi.doMock('../../src/systems/EtaSupport.bs.js', () => ({
      dismissEtaToast: vi.fn(),
      dispatchCalculatingEtaToast: vi.fn(),
    }));
    vi.doMock('../../src/utils/ProgressBar.bs.js', () => ({ updateProgressBar: vi.fn() }));
    vi.doMock('../../src/core/SceneInventory.bs.js', () => ({ getActiveScenes: vi.fn(() => ['scene-1']) }));
    vi.doMock('../../src/core/NotificationTypes.bs.js', () => ({ defaultTimeoutMs: vi.fn(() => 1000) }));
    vi.doMock('../../src/systems/TeaserStyleConfig.bs.js', () => teaserStyleConfigMock);
    vi.doMock('../../src/systems/OperationLifecycle.bs.js', () => operationLifecycleMock);
    vi.doMock('../../src/systems/TeaserLogicHelpers.bs.js', () => ({
      parseTeaserProgressMetrics: vi.fn(() => ({ pct: 0 })),
      signalIsAborted: vi.fn(() => false),
    }));
    vi.doMock('../../src/systems/TeaserStyleCatalog.bs.js', () => styleCatalogMock);
    vi.doMock('../../src/core/NotificationManager.bs.js', () => ({ dispatch: vi.fn() }));
    vi.doMock('../../src/systems/ProjectConnectivity.bs.js', () => ({
      validateProjectForGeneration: vi.fn(() => ({ TAG: 'Ok', _0: undefined })),
    }));
    vi.doMock('../../src/systems/TeaserRendererRegistry.bs.js', () => renderRegistryMock);
    vi.doMock('../../src/systems/TeaserOfflineCfrRenderer.bs.js', () => offlineRendererMock);
    vi.doMock('../../src/systems/TeaserHeadlessLogicSupport.bs.js', () => ({
      handleProgress: vi.fn(),
      handleFailure: vi.fn(),
    }));

    const mod = await import('../../src/systems/TeaserHeadlessLogic.bs.js');

    await mod.startHeadlessTeaserWithStyle(
      finalizeTeaser,
      'webm',
      'cinematic',
      'fast',
      getState,
      dispatch,
      undefined,
      undefined
    );

    expect(teaserStyleConfigMock.resolvePanSpeedOption).toHaveBeenCalledWith('fast');
    expect(teaserStyleConfigMock.applyPanSpeedOption).toHaveBeenCalledWith(baseManifest, fastOption);
    expect(offlineRendererMock.renderWebMDeterministic).toHaveBeenCalledWith(
      retimedManifest,
      true,
      getState,
      dispatch,
      undefined,
      expect.any(Function)
    );

    teaserStyleConfigMock.applyPanSpeedOption.mockClear();
    teaserStyleConfigMock.resolvePanSpeedOption.mockClear();
    offlineRendererMock.renderWebMDeterministic.mockClear();

    await mod.startHeadlessTeaserWithStyle(
      finalizeTeaser,
      'webm',
      'fast_shots',
      'fast',
      getState,
      dispatch,
      undefined,
      undefined
    );

    expect(teaserStyleConfigMock.resolvePanSpeedOption).not.toHaveBeenCalled();
    expect(teaserStyleConfigMock.applyPanSpeedOption).not.toHaveBeenCalled();
    expect(offlineRendererMock.renderWebMDeterministic).toHaveBeenCalledWith(
      baseManifest,
      true,
      getState,
      dispatch,
      undefined,
      expect.any(Function)
    );
    expect(operationLifecycleMock.start.mock.calls[1][5].panSpeedId).toBe('standard');
  });
});
