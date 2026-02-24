// @efficiency: infra-adapter
open Vitest
open Types

%%raw(`
  const loggerMock = {
    startOperation: globalThis.vi.fn(),
    endOperation: globalThis.vi.fn(),
    info: globalThis.vi.fn(),
    warn: globalThis.vi.fn(),
    error: globalThis.vi.fn(),
    debug: globalThis.vi.fn(),
    initialized: globalThis.vi.fn(),
    setOperationId: globalThis.vi.fn(),
    getErrorDetails: (exn) => ["", ""],
    castToJson: (obj) => obj
  };
  globalThis.vi.mock('../../src/utils/Logger.bs.js', () => loggerMock);

  const opMock = {
    start: globalThis.vi.fn().mockReturnValue("op_123"),
    complete: globalThis.vi.fn(),
    fail: globalThis.vi.fn(),
    progress: globalThis.vi.fn(),
    registerCancel: globalThis.vi.fn(),
    isActive: globalThis.vi.fn().mockReturnValue(true),
    cancel: globalThis.vi.fn(),
  };
  globalThis.vi.mock('../../src/systems/OperationLifecycle.bs.js', () => opMock);

  const pathfinderMock = {
    getWalkPath: globalThis.vi.fn(),
    getTimelinePath: globalThis.vi.fn(),
  };
  globalThis.vi.mock('../../src/systems/TeaserPathfinder.bs.js', () => pathfinderMock);

  const startRecordingFn = globalThis.vi.fn();
  const stopRecordingFn = globalThis.vi.fn();
  const loadLogoFn = globalThis.vi.fn();
  const startAnimationLoopFn = globalThis.vi.fn();
  const pauseRecordingFn = globalThis.vi.fn();
  const resumeRecordingFn = globalThis.vi.fn();
  const getGhostCanvasFn = globalThis.vi.fn();
  const setSnapshotFn = globalThis.vi.fn();
  const setFadeOpacityFn = globalThis.vi.fn();
  const getRecordedBlobsFn = globalThis.vi.fn(() => []);
  const renderFrameFn = globalThis.vi.fn();
  const requestDeterministicFrameFn = globalThis.vi.fn();

  const recorderMock = {
    startRecording: startRecordingFn,
    stopRecording: stopRecordingFn,
    loadLogo: loadLogoFn,
    startAnimationLoop: startAnimationLoopFn,
    pauseRecording: pauseRecordingFn,
    resumeRecording: resumeRecordingFn,
    getGhostCanvas: getGhostCanvasFn,
    setSnapshot: setSnapshotFn,
    setFadeOpacity: setFadeOpacityFn,
    getRecordedBlobs: getRecordedBlobsFn,
    renderFrame: renderFrameFn,
    requestDeterministicFrame: requestDeterministicFrameFn,
    Recorder: {
      startRecording: startRecordingFn,
      stopRecording: stopRecordingFn,
      pause: pauseRecordingFn,
      resume: resumeRecordingFn,
      getGhostCanvas: getGhostCanvasFn,
      getRecordedBlobs: getRecordedBlobsFn,
      setSnapshot: setSnapshotFn,
      setFadeOpacity: setFadeOpacityFn,
      loadLogo: loadLogoFn,
      startAnimationLoop: startAnimationLoopFn,
      renderFrame: renderFrameFn,
      requestDeterministicFrame: requestDeterministicFrameFn,
    }
  };
  globalThis.vi.mock('../../src/systems/TeaserRecorder.bs.js', () => recorderMock);

  const stateMock = {
    getState: globalThis.vi.fn(),
    dispatch: globalThis.vi.fn(),
    SetIsTeasing: (v) => ({ type: 'SetIsTeasing', payload: v })
  };
  globalThis.vi.mock('../../src/core/AppStateBridge.bs.js', () => stateMock);

  const serverMock = {
    generateServerTeaser: globalThis.vi.fn(),
    Server: { generateServerTeaser: globalThis.vi.fn() }
  };
  globalThis.vi.mock('../../src/systems/ServerTeaser.bs.js', () => serverMock);

  globalThis.vi.mock('../../src/utils/EventBus.bs.js', () => ({
    dispatch: globalThis.vi.fn(),
  }));

  globalThis.vi.mock('../../src/components/ProgressBar.bs.js', () => ({
    updateProgressBar: globalThis.vi.fn()
  }));

  globalThis.vi.mock('../../src/systems/DownloadSystem.bs.js', () => ({
    saveBlob: globalThis.vi.fn()
  }));

  const manifestMock = {
    generateSimulationParityManifest: globalThis.vi.fn().mockReturnValue({
      version: "motion-spec-v1",
      fps: 10,
      canvasWidth: 1920,
      canvasHeight: 1080,
      includeIntroPan: false,
      shots: [{
        sceneId: "scene1",
        arrivalPose: { yaw: 0.0, pitch: 0.0, hfov: 80.0 },
        animationSegments: [],
        transitionOut: null,
        pathData: null,
        waitBeforePanMs: 0,
        blinkAfterPanMs: 0,
      }],
    }),
    generateManifest: globalThis.vi.fn().mockReturnValue({
      fps: 10,
      shots: [],
    }),
    calculateTotalManifestDuration: globalThis.vi.fn().mockReturnValue(100.0),
  };
  globalThis.vi.mock('../../src/systems/TeaserManifest.bs.js', () => manifestMock);

  globalThis.manifestMock = manifestMock;

  const playbackMock = {
    getManifestStateAt: globalThis.vi.fn().mockReturnValue({
      sceneId: "scene1",
      pose: {yaw: 0.0, pitch: 0.0, hfov: 80.0},
      fadeOpacity: 0.0
    }),
    wait: globalThis.vi.fn().mockResolvedValue(undefined),
    waitForViewerReady: globalThis.vi.fn().mockResolvedValue(true),
  };
  globalThis.vi.mock('../../src/systems/TeaserPlayback.bs.js', () => playbackMock);

  globalThis.playbackMock = playbackMock;
  globalThis.loggerMock = loggerMock;
  globalThis.stateMock = stateMock;
  globalThis.pathfinderMock = pathfinderMock;
  globalThis.recorderMock = recorderMock;
  globalThis.serverMock = serverMock;
`)

/* Types */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"
@get external getMock: 'a => mockFn = "mock"

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"
@send external toHaveBeenCalledWith2: (expectation, 'a, 'b) => unit = "toHaveBeenCalledWith"
@send external toHaveBeenCalledWith3: (expectation, 'a, 'b, 'c) => unit = "toHaveBeenCalledWith"

/* Mocks */
@module("../../src/systems/TeaserPathfinder.bs.js") external mockGetWalkPath: mockFn = "getWalkPath"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockStartRecording: mockFn = "startRecording"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockStopRecording: mockFn = "stopRecording"
@module("../../src/systems/TeaserRecorder.bs.js") external mockLoadLogo: mockFn = "loadLogo"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockStartAnimationLoop: mockFn = "startAnimationLoop"
@module("../../src/core/AppStateBridge.bs.js") external mockGetState: mockFn = "getState"
@module("../../src/core/AppStateBridge.bs.js") external mockDispatch: mockFn = "dispatch"
@module("../../src/systems/ServerTeaser.bs.js")
external mockGenerateServerTeaser: mockFn = "generateServerTeaser"

let loadManager = async () => {
  let m = await %raw(`import('../../src/systems/Teaser.bs.js')`)
  m
}

let makeMockScene = (~id, ~name, ()) => {
  id,
  name,
  file: Url(name ++ ".jpg"),
  tinyFile: None,
  originalFile: None,
  hotspots: [],
  category: "default",
  floor: "ground",
  label: name,
  quality: None,
  colorGroup: None,
  _metadataSource: "test",
  categorySet: false,
  labelSet: false,
  isAutoForward: false,
  sequenceId: 0,
}

%%raw(`
  globalThis.beforeEach(() => {
    globalThis.vi.clearAllMocks();
    
    // Setup mock DOM for rendering check
    const div = document.createElement('div');
    div.className = 'panorama-layer active';
    const canvas = document.createElement('canvas');
    div.appendChild(canvas);
    document.body.appendChild(div);

    globalThis.stateMock.getState.mockReturnValue({
      "inventory": new Map([
        ["scene1", {scene: {id: "scene1", name: "S1", file: {TAG: 'Url', _0: "S1.jpg"}, hotspots: [], category: "default", floor: "ground", label: "S1", _metadataSource: "test", categorySet: false, labelSet: false, isAutoForward: false, sequenceId: 0}, status: 0}],
        ["scene2", {scene: {id: "scene2", name: "S2", file: {TAG: 'Url', _0: "S2.jpg"}, hotspots: [], category: "default", floor: "ground", label: "S2", _metadataSource: "test", categorySet: false, labelSet: false, isAutoForward: false, sequenceId: 0}, status: 0}]
      ]),
      "sceneOrder": ["scene1", "scene2"],
      "tourName": "TestTour",
      "simulation": {"status": {TAG: 'Idle'}, "visitedLinkIds": []},
    });

    globalThis.recorderMock.loadLogo.mockResolvedValue(null);
    globalThis.recorderMock.startRecording.mockReturnValue(true);
    globalThis.serverMock.generateServerTeaser.mockResolvedValue({TAG: 'Ok', _0: new Blob([])});
    
    globalThis.manifestMock.calculateTotalManifestDuration.mockReturnValue(100.0);
    globalThis.manifestMock.generateManifest.mockReturnValue({
      fps: 10,
      shots: [{ sceneId: 'scene1', animationSegments: [] }],
    });
    globalThis.manifestMock.generateSimulationParityManifest.mockReturnValue({
      version: "motion-spec-v1",
      fps: 10,
      canvasWidth: 1920,
      canvasHeight: 1080,
      includeIntroPan: false,
      shots: [{
        sceneId: "scene1",
        arrivalPose: { yaw: 0.0, pitch: 0.0, hfov: 80.0 },
        animationSegments: [],
        transitionOut: null,
        pathData: null,
        waitBeforePanMs: 0,
        blinkAfterPanMs: 0,
      }],
    });

    globalThis.playbackMock.getManifestStateAt.mockReturnValue({
      sceneId: "scene1",
      pose: {yaw: 0.0, pitch: 0.0, hfov: 80.0},
      fadeOpacity: 0.0
    });
  });

  globalThis.afterEach(() => {
    document.body.innerHTML = '';
  });
`)

describe("TeaserManager", () => {
  test("Config constants are correct", t => {
    t->expect(TeaserStyleConfig.standardConfig.clipDuration)->Expect.toBe(2500.0)
    t->expect(TeaserStyleConfig.slowConfig.clipDuration)->Expect.toBe(4000.0)
    t->expect(TeaserStyleConfig.punchyConfig.clipDuration)->Expect.toBe(1800.0)
    t->expect(TeaserStyleConfig.standardConfig.cameraPanOffset)->Expect.toBe(20.0)
  })

  testAsync("startAutoTeaser fetches path and starts recording (Deterministic Local)", async t => {
    let format = "webm"
    let manager = await loadManager()
    let createLocalState = () => {
      let scene1 = makeMockScene(~id="scene1", ~name="S1", ())
      let scene2 = makeMockScene(~id="scene2", ~name="S2", ())
      {
        ...TestUtils.createMockState(~scenes=[scene1, scene2], ~activeIndex=0, ()),
        tourName: "TestTour",
      }
    }

    let localGetState: unit => Types.state = () => createLocalState()


    let startAutoTeaser: (
      string,
      ~getState: unit => Types.state,
      ~dispatch: Actions.action => unit,
    ) => promise<unit> = manager["startAutoTeaser"]

    try {
      await startAutoTeaser(format, ~getState=localGetState, ~dispatch=AppStateBridge.dispatch)
    } catch {
    | exn => Console.error2("Teaser failed:", exn)
    }

    let pathfinderCalls = %raw(`globalThis.pathfinderMock.getWalkPath.mock.calls.length`)
    let loadLogoCalls = %raw(`globalThis.recorderMock.loadLogo.mock.calls.length`)
    let startRecordingCalls = %raw(`globalThis.recorderMock.startRecording.mock.calls.length`)

    t->expect(pathfinderCalls)->Expect.toBe(0)
    t->expect(loadLogoCalls > 0)->Expect.toBe(true)
    t->expect(startRecordingCalls > 0)->Expect.toBe(true)
  })
})
