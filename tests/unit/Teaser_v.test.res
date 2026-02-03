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
  globalThis.pannellumViewer = {
    isLoaded: globalThis.vi.fn().mockReturnValue(true),
    getScene: globalThis.vi.fn().mockReturnValue("s1"),
    setYaw: globalThis.vi.fn(),
    setPitch: globalThis.vi.fn(),
    on: globalThis.vi.fn(),
    destroy: globalThis.vi.fn(),
  };

  // Mock GlobalStateBridge
  const globalStateMock = {
    getState: globalThis.vi.fn().mockReturnValue({scenes: [], tourName: ""}),
    dispatch: globalThis.vi.fn(),
    setDispatch: globalThis.vi.fn(),
    setState: globalThis.vi.fn(),
  };
  globalThis.globalStateMock = globalStateMock;
  globalThis.vi.mock('../../src/core/GlobalStateBridge.bs.js', () => globalStateMock);
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
  })

  afterEach(() => {
    ignore(%raw(`globalThis.vi.useRealTimers()`))
  })

  testAsync("startAutoTeaser should do nothing if no scenes exist", async t => {
    let mockState = {...State.initialState, scenes: []}
    let _ = %raw(`(s) => globalThis.globalStateMock.getState.mockReturnValue(s)`)(mockState)

    let teaser = await loadTeaser()
    let startAutoTeaser: (string, bool, string, bool) => promise<unit> = teaser["startAutoTeaser"]
    await startAutoTeaser("fast", false, "webm", false)

    let called = %raw(`globalThis.serverMock.Server.generateServerTeaser.mock.calls.length`)
    t->expect(called)->Expect.toBe(0)

    let pathfinderCalled = %raw(`globalThis.pathfinderMock.getWalkPath.mock.calls.length`)
    t->expect(pathfinderCalled)->Expect.toBe(0)
  })

  testAsync("startAutoTeaser (cinematic + mp4) should call generateServerTeaser", async t => {
    let scene = makeMockScene(~id="s1")
    let mockState = {...State.initialState, scenes: [scene], tourName: "Test Tour"}
    let _ = %raw(`(s) => globalThis.globalStateMock.getState.mockReturnValue(s)`)(mockState)

    // Mock success response
    ignore(
      %raw(`(() => {
        let successBlob = new Blob([], {type: 'video/mp4'})
        globalThis.serverMock.Server.generateServerTeaser.mockResolvedValue({TAG: 'Ok', _0: successBlob})
    })()`),
    )

    let teaser = await loadTeaser()
    let startAutoTeaser: (string, bool, string, bool) => promise<unit> = teaser["startAutoTeaser"]
    // Start async operation
    let promise = startAutoTeaser("cinematic", false, "mp4", false)

    // Wait for promise chain
    await (%raw(`Promise.resolve()`): promise<unit>)
    await (%raw(`Promise.resolve()`): promise<unit>)
    await (%raw(`Promise.resolve()`): promise<unit>)

    // Wait for promise to resolve
    await promise

    let called = %raw(`globalThis.serverMock.Server.generateServerTeaser.mock.calls.length`)
    t->expect(called)->Expect.toBe(1)

    // Should save blob
    let downloadCalled = %raw(`globalThis.downloadMock.saveBlob.mock.calls.length`)
    t->expect(downloadCalled)->Expect.toBe(1)
  })

  testAsync("startAutoTeaser (client-side) should record and save webm", async t => {
    let scene = makeMockScene(~id="s1")
    let mockState = {...State.initialState, scenes: [scene], tourName: "Test Tour"}
    let _ = %raw(`(s) => globalThis.globalStateMock.getState.mockReturnValue(s)`)(mockState)

    // Mock Pathfinder success
    ignore(
      %raw(`(() => {
        let step1 = {
        "idx": 0,
        "arrivalView": {"yaw": 0.0, "pitch": 0.0},
        "transitionTarget": undefined
        }
        globalThis.pathfinderMock.getWalkPath.mockResolvedValue({TAG: 'Ok', _0: [step1]})
    })()`),
    )

    let teaser = await loadTeaser()
    let startAutoTeaser: (string, bool, string, bool) => promise<unit> = teaser["startAutoTeaser"]
    let promise = startAutoTeaser("fast", false, "webm", false)

    // Advance timers to simulate playback duration
    let rec advance = async count => {
      if count > 20 {
        ()
      } else {
        let p: promise<unit> = %raw(`globalThis.vi.advanceTimersByTimeAsync(1000)`)
        await p
        await advance(count + 1)
      }
    }
    await advance(0)

    await promise

    let pathfinderCalled = %raw(`globalThis.pathfinderMock.getWalkPath.mock.calls.length`)
    t->expect(pathfinderCalled)->Expect.toBe(1)

    let startRecCalled = %raw(`globalThis.recorderMock.Recorder.startRecording.mock.calls.length`)
    t->expect(startRecCalled)->Expect.toBe(1)

    let stopRecCalled = %raw(`globalThis.recorderMock.Recorder.stopRecording.mock.calls.length`)
    t->expect(stopRecCalled)->Expect.toBe(1)

    let downloadCalled = %raw(`globalThis.downloadMock.saveBlob.mock.calls.length`)
    t->expect(downloadCalled)->Expect.toBe(1)
  })

  testAsync("startAutoTeaser should handle pathfinder failure", async t => {
    let scene = makeMockScene(~id="s1")
    let mockState = {...State.initialState, scenes: [scene]}
    let _ = %raw(`(s) => globalThis.globalStateMock.getState.mockReturnValue(s)`)(mockState)

    // Mock Pathfinder error
    ignore(
      %raw(`globalThis.pathfinderMock.getWalkPath.mockResolvedValue({TAG: 'Error', _0: "No path found"})`),
    )

    let teaser = await loadTeaser()
    let startAutoTeaser: (string, bool, string, bool) => promise<unit> = teaser["startAutoTeaser"]
    await startAutoTeaser("fast", false, "webm", false)

    let startRecCalled = %raw(`globalThis.recorderMock.Recorder.startRecording.mock.calls.length`)
    t->expect(startRecCalled)->Expect.toBe(0)
  })
})
