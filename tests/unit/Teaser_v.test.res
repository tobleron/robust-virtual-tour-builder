// @efficiency: infra-adapter
/* tests/unit/Teaser_v.test.res */
open Vitest
open Types

let makeMockScene = (~id) => {
  {
    id,
    name: "Scene " ++ id,
    label: "",
    file: Url(""),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "",
    floor: "",
    quality: None,
    colorGroup: None,
    categorySet: false,
    labelSet: false,
    _metadataSource: "user",
    isAutoForward: false,
    sequenceId: 0,
  }
}

%raw(`
(() => {
  // Mock TeaserRecorder
  const recorderMock = {
    Recorder: {
      loadLogo: globalThis.vi.fn().mockResolvedValue({}),
      startAnimationLoop: globalThis.vi.fn(),
      startRecording: globalThis.vi.fn().mockReturnValue(true),
      stopRecording: globalThis.vi.fn(),
      getRecordedBlobs: globalThis.vi.fn().mockReturnValue([new Blob([], {type: 'video/webm'})]),
      internalState: { contents: { ghostCanvas: undefined, snapshotCanvas: undefined } },
      setFadeOpacity: globalThis.vi.fn(),
      pause: globalThis.vi.fn(),
      resume: globalThis.vi.fn(),
    }
  };
  globalThis.recorderMock = recorderMock;
  globalThis.vi.mock('../../src/systems/TeaserRecorder.bs.js', () => recorderMock);

  // Mock TeaserPathfinder
  const pathfinderMock = {
    getWalkPath: globalThis.vi.fn(),
  };
  globalThis.pathfinderMock = pathfinderMock;
  globalThis.vi.mock('../../src/systems/TeaserPathfinder.bs.js', () => pathfinderMock);

  // Mock ServerTeaser
  const serverMock = {
    Server: {
      generateServerTeaser: globalThis.vi.fn(),
    }
  };
  globalThis.serverMock = serverMock;
  globalThis.vi.mock('../../src/systems/ServerTeaser.bs.js', () => serverMock);

  // Mock DownloadSystem
  const downloadMock = {
    saveBlob: globalThis.vi.fn(),
  };
  globalThis.downloadMock = downloadMock;
  globalThis.vi.mock('../../src/systems/DownloadSystem.bs.js', () => downloadMock);

  // Mock VideoEncoder
  const videoEncoderMock = {
    transcodeWebMToMP4: globalThis.vi.fn(),
  };
  globalThis.videoEncoderMock = videoEncoderMock;
  globalThis.vi.mock('../../src/systems/VideoEncoder.bs.js', () => videoEncoderMock);

  // Mock ProgressBar
  const progressBarMock = {
    updateProgressBar: globalThis.vi.fn(),
  };
  globalThis.progressBarMock = progressBarMock;
  globalThis.vi.mock('../../src/utils/ProgressBar.bs.js', () => progressBarMock);

  // Mock Viewer instance
  const mockV = {
    _sceneId: "s1",
    isLoaded: globalThis.vi.fn().mockReturnValue(true),
    getScene: globalThis.vi.fn().mockReturnValue("s1"),
    setYaw: globalThis.vi.fn(),
    setPitch: globalThis.vi.fn(),
    on: globalThis.vi.fn(),
    destroy: globalThis.vi.fn(),
  };
  globalThis.pannellumViewer = mockV;

  // Mock AppStateBridge
  const globalStateMock = {
    getState: globalThis.vi.fn().mockReturnValue({scenes: [], tourName: ""}),
    dispatch: globalThis.vi.fn(),
    registerDispatch: globalThis.vi.fn(),
    updateState: globalThis.vi.fn(),
  };
  globalThis.globalStateMock = globalStateMock;
  globalThis.vi.mock('../../src/core/AppStateBridge.bs.js', () => globalStateMock);

  // Mock Logger
  globalThis.vi.mock('../../src/utils/Logger.bs.js', () => ({
    info: globalThis.vi.fn(),
    error: globalThis.vi.fn(),
    debug: globalThis.vi.fn(),
    warn: globalThis.vi.fn(),
    initialized: globalThis.vi.fn(),
    setOperationId: globalThis.vi.fn(),
    castToJson: (obj) => obj,
    getErrorDetails: () => ["", ""]
  }));

  globalThis.vi.mock('../../src/systems/OperationLifecycle.bs.js', () => ({
    start: globalThis.vi.fn().mockReturnValue("op_123"),
    complete: globalThis.vi.fn(),
    fail: globalThis.vi.fn(),
    progress: globalThis.vi.fn(),
    registerCancel: globalThis.vi.fn(),
    isActive: globalThis.vi.fn().mockReturnValue(true),
    cancel: globalThis.vi.fn(),
  }));
})()
`)

describe("Teaser System", () => {
  let loadTeaser = async () => {
    let m = await %raw(`import('../../src/systems/Teaser.bs.js')`)
    m
  }

  beforeEach(() => {
    ignore(%raw(`globalThis.vi.clearAllMocks()`))
    ignore(%raw(`globalThis.vi.useFakeTimers()`))

    // Set up active viewport in Pool
    ViewerSystem.Pool.pool := [
        {
          id: "primary-a",
          containerId: "panorama-a",
          status: #Active,
          instance: None,
          cleanupTimeout: None,
        },
        {
          id: "primary-b",
          containerId: "panorama-b",
          status: #Background,
          instance: None,
          cleanupTimeout: None,
        },
      ]

    // Register the mock instance from global scope
    let v = %raw(`globalThis.pannellumViewer`)
    ViewerSystem.Pool.registerInstance("panorama-a", v)
  })

  afterEach(() => {
    ignore(%raw(`globalThis.vi.useRealTimers()`))
  })

  testAsync("startAutoTeaser should do nothing if no scenes exist", async t => {
    let mockState = State.initialState
    let _ = %raw(`(s) => globalThis.globalStateMock.getState.mockReturnValue(s)`)(mockState)

    let teaser = await loadTeaser()
    let startAutoTeaser: (
      string,
      ~getState: unit => Types.state,
      ~dispatch: Actions.action => unit,
    ) => promise<unit> = teaser["startAutoTeaser"]
    await startAutoTeaser(
      "webm",
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

    let called = %raw(`globalThis.serverMock.Server.generateServerTeaser.mock.calls.length`)
    t->expect(called)->Expect.toBe(0)

    let pathfinderCalled = %raw(`globalThis.pathfinderMock.getWalkPath.mock.calls.length`)
    t->expect(pathfinderCalled)->Expect.toBe(0)
  })

  testAsync("startAutoTeaser should handle pathfinder failure", async t => {
    let scene = makeMockScene(~id="s1")
    let mockState = TestUtils.createMockState(~scenes=[scene], ())
    let _ = %raw(`(s) => globalThis.globalStateMock.getState.mockReturnValue(s)`)(mockState)

    // Mock Pathfinder error
    ignore(
      %raw(`globalThis.pathfinderMock.getWalkPath.mockResolvedValue({TAG: 'Error', _0: "No path found"})`),
    )

    let teaser = await loadTeaser()
    let startAutoTeaser: (
      string,
      ~getState: unit => Types.state,
      ~dispatch: Actions.action => unit,
    ) => promise<unit> = teaser["startAutoTeaser"]
    await startAutoTeaser(
      "webm",
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )

    let startRecCalled = %raw(`globalThis.recorderMock.Recorder.startRecording.mock.calls.length`)
    t->expect(startRecCalled)->Expect.toBe(0)
  })
})
