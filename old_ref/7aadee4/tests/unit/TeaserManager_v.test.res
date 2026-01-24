open Vitest
open TeaserManager

/* Types */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"

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
`)

describe("TeaserManager", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
    mockGetState->mockReturnValue({
      "scenes": [{"id": "scene1"}, {"id": "scene2"}],
      "tourName": "TestTour",
    })
    mockLoadLogo->mockResolvedValue(null)
    mockGetWalkPath->mockResolvedValue(Ok([])) // Empty path for basic test
    mockStartRecording->mockReturnValue(true)
  })

  test("Config constants are correct", t => {
    t->expect(fastConfig.clipDuration)->Expect.toBe(2500.0)
    t->expect(slowConfig.clipDuration)->Expect.toBe(4000.0)
    t->expect(punchyConfig.clipDuration)->Expect.toBe(1800.0)
    t->expect(fastConfig.cameraPanOffset)->Expect.toBe(20.0)
  })

  testAsync("startAutoTeaser fetches path and starts recording", async t => {
    let style = "fast"
    let includeLogo = true
    let format = "webm"
    let skipAutoForward = false

    await startAutoTeaser(style, includeLogo, format, skipAutoForward)

    expectCall(mockGetWalkPath)->toHaveBeenCalledWith2(
      // scenes are passed. Since I mocked getState to return scenes, they should be passed
      [%raw(`{"id": "scene1"}`), %raw(`{"id": "scene2"}`)],
      skipAutoForward,
    )

    expectCall(mockLoadLogo)->toHaveBeenCalled()
    expectCall(mockStartAnimationLoop)->toHaveBeenCalled()
    expectCall(mockStartRecording)->toHaveBeenCalled()

    t->expect(true)->Expect.toBe(true)
  })
})
