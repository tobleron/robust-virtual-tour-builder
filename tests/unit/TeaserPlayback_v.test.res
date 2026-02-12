// @efficiency: infra-adapter
open Vitest
open Teaser.Playback
open Teaser.State

/* Types */
type mockFn
@send external mockResolvedValue: (mockFn, 'a) => unit = "mockResolvedValue"
@send external mockReturnValue: (mockFn, 'a) => unit = "mockReturnValue"
@get external getMock: 'a => mockFn = "mock"

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalled: (expectation, unit) => unit = "toHaveBeenCalled"
@send external toHaveBeenCalledWith: (expectation, 'a) => unit = "toHaveBeenCalledWith"

@scope("vi") @val external useFakeTimers: unit => unit = "useFakeTimers"
@scope("vi") @val external useRealTimers: unit => unit = "useRealTimers"
@scope("vi") @val
external advanceTimersByTimeAsync: int => promise<unit> = "advanceTimersByTimeAsync"

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

/* Expose internalState from the mock */
type internalStateContent = {
  ghostCanvas: option<Dom.element>,
  snapshotCanvas: option<Dom.element>,
}
type internalStateRef = {mutable contents: internalStateContent}
@module("../../src/systems/TeaserRecorder.bs.js")
external mockInternalState: internalStateRef = "internalState"

@module("../../src/core/AppStateBridge.bs.js") external mockGetState: mockFn = "getState"
@module("../../src/core/AppStateBridge.bs.js") external mockDispatch: mockFn = "dispatch"

@module("../../src/utils/Logger.bs.js") external mockDebug: mockFn = "debug"

%%raw(`
  import { vi } from 'vitest';

  vi.mock('../../src/systems/TeaserRecorder.bs.js', () => {
    const internalState = { contents: { ghostCanvas: null, snapshotCanvas: null } };
    const startRecording = vi.fn();
    const stopRecording = vi.fn();
    const pauseRecording = vi.fn();
    const resumeRecording = vi.fn();
    const getGhostCanvas = vi.fn();
    const setSnapshot = vi.fn();
    const setFadeOpacity = vi.fn();
    const loadLogo = vi.fn();
    const startAnimationLoop = vi.fn();
    return {
      internalState, // Exported top-level ref
      startRecording, stopRecording, pauseRecording, resumeRecording,
      getGhostCanvas, setSnapshot, setFadeOpacity, loadLogo, startAnimationLoop,
      Recorder: {
        internalState, // Exposed on Recorder module too
        startRecording, stopRecording, pause: pauseRecording, resume: resumeRecording,
        getGhostCanvas, setSnapshot, setFadeOpacity, loadLogo, startAnimationLoop,
      }
    };
  });

  vi.mock('../../src/core/AppStateBridge.bs.js', () => ({
    getState: vi.fn(),
    dispatch: vi.fn(),
    SetIsTeasing: (v) => ({ type: 'SetIsTeasing', payload: v })
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
    useFakeTimers()

    // Reset internal state
    mockInternalState.contents = {ghostCanvas: None, snapshotCanvas: None}

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

  afterEach(() => {
    useRealTimers()
  })

  testAsync("prepareFirstScene loads scene and sets orientation", async t => {
    let step: Teaser.Pathfinder.step = {
      idx: 0,
      arrivalView: {yaw: 10.0, pitch: 5.0},
      transitionTarget: Some({
        yaw: 0.0,
        pitch: 0.0,
        targetName: "scene1",
        timelineItemId: None,
      }),
    }

    let p = prepareFirstScene(
      step,
      "fast",
      fastConfig,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )
    await advanceTimersByTimeAsync(2000)
    await p

    // Verify Dispatch
    let dispatchCalls = %raw(`mockDispatch.mock.calls`)
    t->expect(Array.length(dispatchCalls))->Expect.Int.toBeGreaterThan(0)

    // Verify Viewer.setYaw was called
    let setYawCalls = %raw(`global.window.pannellumViewer.setYaw.mock.calls`)
    t->expect(Array.length(setYawCalls))->Expect.Int.toBeGreaterThan(0)
  })

  testAsync("transitionToNextShot handles recording pause/resume and fade", async t => {
    let step: Teaser.Pathfinder.step = {
      idx: 1,
      arrivalView: {yaw: 20.0, pitch: 0.0},
      transitionTarget: Some({
        yaw: 0.0,
        pitch: 0.0,
        targetName: "scene2",
        timelineItemId: None,
      }),
    }

    // Set ghostCanvas in the mocked internalState
    // We use a dummy object for canvas
    let dummyCanvas: Dom.element = %raw(`{ tagName: 'CANVAS' }`)
    mockInternalState.contents = {ghostCanvas: Some(dummyCanvas), snapshotCanvas: None}

    // Next scene must be "scene2" for waitForViewerReady
    let _ = %raw(`global.window.pannellumViewer.getScene = () => "scene2"`)

    let p = transitionToNextShot(
      0,
      step,
      "fast",
      fastConfig,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )
    await advanceTimersByTimeAsync(3000) // 1000ms fade + waits
    await p

    // Verify sequence:

    // 1. internalState.snapshotCanvas should be set (checked via logic)
    // Actually, TeaserLogic does: internalState := {...internalState.contents, snapshotCanvas: Some(g)}
    // So we can check mockInternalState.contents.snapshotCanvas
    t->expect(mockInternalState.contents.snapshotCanvas)->Expect.toBe(Some(dummyCanvas))

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
