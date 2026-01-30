open Vitest
open Teaser.Manager
open Teaser.State
open Types

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

/* Mocks */
@module("../../src/systems/TeaserPathfinder.bs.js") external mockGetWalkPath: mockFn = "getWalkPath"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockStartRecording: mockFn = "startRecording"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockStopRecording: mockFn = "stopRecording"
@module("../../src/systems/TeaserRecorder.bs.js") external mockLoadLogo: mockFn = "loadLogo"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockStartAnimationLoop: mockFn = "startAnimationLoop"
@module("../../src/core/GlobalStateBridge.bs.js") external mockGetState: mockFn = "getState"
@module("../../src/core/GlobalStateBridge.bs.js") external mockDispatch: mockFn = "dispatch"
@module("../../src/systems/ServerTeaser.bs.js")
external mockGenerateServerTeaser: mockFn = "generateServerTeaser"

%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/TeaserPathfinder.bs.js', () => ({
    getWalkPath: vi.fn(),
    getTimelinePath: vi.fn(),
  }));

  vi.mock('../../src/systems/TeaserRecorder.bs.js', () => ({
    startRecording: vi.fn(),
    stopRecording: vi.fn(),
    loadLogo: vi.fn(),
    startAnimationLoop: vi.fn(),
    pauseRecording: vi.fn(),
    resumeRecording: vi.fn(),
    getGhostCanvas: vi.fn(),
    setSnapshot: vi.fn(),
    setFadeOpacity: vi.fn(),
    getRecordedBlobs: vi.fn(() => []),
  }));

  vi.mock('../../src/core/GlobalStateBridge.bs.js', () => ({
    getState: vi.fn(),
    dispatch: vi.fn(),
    SetIsTeasing: (v) => ({ type: 'SetIsTeasing', payload: v })
  }));

  vi.mock('../../src/systems/ServerTeaser.bs.js', () => ({
    generateServerTeaser: vi.fn(),
  }));

  vi.mock('../../src/utils/Logger.bs.js', () => ({
    startOperation: vi.fn(),
    endOperation: vi.fn(),
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    debug: vi.fn(),
    getErrorDetails: (exn) => ["", ""],
    castToJson: (obj) => obj
  }));

  vi.mock('../../src/utils/EventBus.bs.js', () => ({
    dispatch: vi.fn(),
  }));

  vi.mock('../../src/components/ProgressBar.bs.js', () => ({
    updateProgressBar: vi.fn()
  }));

  vi.mock('../../src/systems/DownloadSystem.bs.js', () => ({
    saveBlob: vi.fn()
  }));
`)

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
}

describe("TeaserManager", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
    mockGetState->mockReturnValue({
      "scenes": [
        makeMockScene(~id="scene1", ~name="S1", ()),
        makeMockScene(~id="scene2", ~name="S1", ()),
      ],
      "tourName": "TestTour",
      "simulation": {"status": "Idle", "visitedScenes": []},
    })
    mockLoadLogo->mockResolvedValue(%raw("null"))
    mockGetWalkPath->mockResolvedValue(Ok([])) // Empty path for basic test
    mockStartRecording->mockReturnValue(true)
    mockGenerateServerTeaser->mockResolvedValue(Ok(%raw(`new Blob([])`)))
  })

  test("Config constants are correct", t => {
    t->expect(fastConfig.clipDuration)->Expect.toBe(2500.0)
    t->expect(slowConfig.clipDuration)->Expect.toBe(4000.0)
    t->expect(punchyConfig.clipDuration)->Expect.toBe(1800.0)
    t->expect(fastConfig.cameraPanOffset)->Expect.toBe(20.0)
  })

  testAsync("startAutoTeaser fetches path and starts recording (Client Side)", async t => {
    let style = "fast"
    let includeLogo = true
    let format = "webm"
    let skipAutoForward = false

    await startAutoTeaser(style, includeLogo, format, skipAutoForward)

    expectCall(mockGetWalkPath)->toHaveBeenCalledWith2(
      [makeMockScene(~id="scene1", ~name="S1", ()), makeMockScene(~id="scene2", ~name="S1", ())],
      skipAutoForward,
    )

    expectCall(mockLoadLogo)->toHaveBeenCalled()
    expectCall(mockStartAnimationLoop)->toHaveBeenCalled()
    expectCall(mockStartRecording)->toHaveBeenCalled()

    t->expect(true)->Expect.toBe(true)
  })

  testAsync("startAutoTeaser triggers Server Generation for Cinematic MP4", async t => {
    let style = "cinematic"
    let includeLogo = true
    let format = "mp4"
    let skipAutoForward = false

    await startAutoTeaser(style, includeLogo, format, skipAutoForward)

    // Verify ServerTeaser.generateServerTeaser called
    let calls = %raw(`mockGenerateServerTeaser.mock.calls`)
    t->expect(Array.length(calls))->Expect.toBe(1)

    // Verify SetIsTeasing dispatch
    // We mocked GlobalStateBridge to verify dispatch
    // First arg of generateServerTeaser is state.
    // We should check if dispatch called with SetIsTeasing(true)
    // The mock for SetIsTeasing returns an object.

    let dispatchCalls = %raw(`mockDispatch.mock.calls`)
    t->expect(Array.length(dispatchCalls))->Expect.Int.toBeGreaterThan(0)
  })
})
