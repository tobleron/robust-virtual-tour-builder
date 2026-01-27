open Vitest
open TeaserPlayback
open TeaserState

/* Types */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"
@get external getMock: 'a => mockFn = "mock"

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"

/* Mocks */
@module("../../src/systems/TeaserRecorder.bs.js")
external mockStartRecording: mockFn = "startRecording"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockPauseRecording: mockFn = "pauseRecording"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockResumeRecording: mockFn = "resumeRecording"
@module("../../src/systems/TeaserRecorder.bs.js") external mockSetSnapshot: mockFn = "setSnapshot"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockGetGhostCanvas: mockFn = "getGhostCanvas"
@module("../../src/systems/TeaserRecorder.bs.js")
external mockSetFadeOpacity: mockFn = "setFadeOpacity"

@module("../../src/core/GlobalStateBridge.bs.js") external mockGetState: mockFn = "getState"
@module("../../src/core/GlobalStateBridge.bs.js") external mockDispatch: mockFn = "dispatch"

@module("../../src/utils/Logger.bs.js") external mockDebug: mockFn = "debug"

%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/TeaserRecorder.bs.js', () => ({
    startRecording: vi.fn(),
    stopRecording: vi.fn(),
    pauseRecording: vi.fn(),
    resumeRecording: vi.fn(),
    getGhostCanvas: vi.fn(),
    setSnapshot: vi.fn(),
    setFadeOpacity: vi.fn(),
    loadLogo: vi.fn(),
    startAnimationLoop: vi.fn()
  }));

  vi.mock('../../src/core/GlobalStateBridge.bs.js', () => ({
    getState: vi.fn(),
    dispatch: vi.fn(),
  }));

  vi.mock('../../src/utils/Logger.bs.js', () => ({
    debug: vi.fn(),
    info: vi.fn(),
    error: vi.fn(),
    startOperation: vi.fn(),
    endOperation: vi.fn(),
    getErrorDetails: () => ["", ""],
    castToJson: (obj) => obj
  }));

  // Mock Window methods used in TeaserPlayback
  global.setTimeout = (fn, ms) => {
      // Execute immediately for tests, or use fake timers
      // But TeaserPlayback uses await wait(ms).
      // If we execute immediately, logic flows.
      fn();
      return 1;
  };

  // Mock Viewer on window
  global.window = global; // JSDOM does this
  global.window.pannellumViewer = {
      isLoaded: () => true,
      getScene: () => "scene1",
      setYaw: vi.fn(),
      setPitch: vi.fn(),
      loadScene: vi.fn()
  };
`)

describe("TeaserPlayback", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)

    // Setup Default State
    mockGetState->mockReturnValue({
      "scenes": [
        {
          "id": "scene1",
          "name": "Scene 1",
          "file": null, // Simplified
        },
        {
          "id": "scene2",
          "name": "Scene 2",
          "file": null,
        },
      ],
    })

    // Setup Viewer
    let _ = %raw(`global.window.pannellumViewer.getScene = () => "scene1"`)
  })

  testAsync("prepareFirstScene loads scene and sets orientation", async t => {
    let step: TeaserPathfinder.step = {
      idx: 0,
      arrivalView: {yaw: 10.0, pitch: 5.0},
      transitionTarget: Some({
        yaw: 0.0,
        pitch: 0.0,
        targetName: "scene1",
        timelineItemId: None,
      }),
    }

    // Mock getScene to return something else initially so we can test loading wait?
    // Actually prepareFirstScene dispatches SetActiveScene.

    await prepareFirstScene(step, "fast", fastConfig)

    // Verify Dispatch
    let dispatchCalls = %raw(`mockDispatch.mock.calls`)
    // First arg is action. It's complex to check ReScript variant equality via calls arguments in JS.
    // But we can check calls length.
    t->expect(Array.length(dispatchCalls))->Expect.Int.toBeGreaterThan(0)

    // Verify Viewer.setYaw was called
    let setYawCalls = %raw(`global.window.pannellumViewer.setYaw.mock.calls`)
    t->expect(Array.length(setYawCalls))->Expect.Int.toBeGreaterThan(0)
  })

  testAsync("transitionToNextShot handles recording pause/resume and fade", async t => {
    let step: TeaserPathfinder.step = {
      idx: 1,
      arrivalView: {yaw: 20.0, pitch: 0.0},
      transitionTarget: Some({
        yaw: 0.0,
        pitch: 0.0,
        targetName: "scene2",
        timelineItemId: None,
      }),
    }

    mockGetGhostCanvas->mockReturnValue(Some(%raw(`{}`)))

    // Next scene must be "scene2" for waitForViewerReady
    let _ = %raw(`global.window.pannellumViewer.getScene = () => "scene2"`)

    await transitionToNextShot(0, step, "fast", fastConfig)

    // Verify sequence:
    // 1. setSnapshot
    let setSnapCalls = %raw(`mockSetSnapshot.mock.calls`)
    t->expect(Array.length(setSnapCalls))->Expect.toBe(1)

    // 2. pauseRecording
    let pauseCalls = %raw(`mockPauseRecording.mock.calls`)
    t->expect(Array.length(pauseCalls))->Expect.toBe(1)

    // 3. resumeRecording
    let resumeCalls = %raw(`mockResumeRecording.mock.calls`)
    t->expect(Array.length(resumeCalls))->Expect.toBe(1)

    // 4. setFadeOpacity called multiple times (fade out)
    let fadeCalls = %raw(`mockSetFadeOpacity.mock.calls`)
    t->expect(Array.length(fadeCalls))->Expect.Int.toBeGreaterThan(1)
  })
})
