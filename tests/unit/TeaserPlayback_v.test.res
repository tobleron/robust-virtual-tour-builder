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
@module("../../src/systems/ViewerSystem.bs.js")
external setCurrentViewerSceneId: string => unit = "__setCurrentSceneId"
@module("../../src/systems/ViewerSystem.bs.js") external mockViewerSetYaw: mockFn = "__mockSetYaw"
@module("../../src/systems/ViewerSystem.bs.js")
external mockViewerSetPitch: mockFn = "__mockSetPitch"

@module("../../src/utils/Logger.bs.js") external mockDebug: mockFn = "debug"
@module("../../src/systems/TeaserRecorderSupport.bs.js")
external mockCanvasHasPaintedPixels: mockFn = "canvasHasPaintedPixels"

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
    const renderableCanvas = { tagName: 'CANVAS', width: 1920, height: 1080 };
    const resolveSourceCanvas = vi.fn(() => renderableCanvas);
    return {
      internalState, // Exported top-level ref
      startRecording, stopRecording, pauseRecording, resumeRecording,
      getGhostCanvas, setSnapshot, setFadeOpacity, loadLogo, startAnimationLoop, resolveSourceCanvas,
      Recorder: {
        internalState, // Exposed on Recorder module too
        startRecording, stopRecording, pause: pauseRecording, resume: resumeRecording,
        getGhostCanvas, setSnapshot, setFadeOpacity, loadLogo, startAnimationLoop, resolveSourceCanvas,
      }
    };
  });

  vi.mock('../../src/core/AppStateBridge.bs.js', () => ({
    getState: vi.fn(),
    dispatch: vi.fn(),
    updateState: vi.fn(),
    SetIsTeasing: (v) => ({ type: 'SetIsTeasing', payload: v })
  }));

  vi.mock('../../src/systems/ViewerSystem.bs.js', () => {
    const Primitive_option = require('@rescript/runtime/lib/es6/Primitive_option.js');
    let currentSceneId = "scene1";
    const mockSetYaw = vi.fn();
    const mockSetPitch = vi.fn();
    const viewer = {
      isLoaded: () => true,
      setYaw: mockSetYaw,
      setPitch: mockSetPitch,
    };
    return {
      __setCurrentSceneId: (id) => { currentSceneId = id; },
      __mockSetYaw: mockSetYaw,
      __mockSetPitch: mockSetPitch,
      getActiveViewer: vi.fn(() => viewer),
      getActiveViewerReadyForScene: vi.fn(() => Primitive_option.some(viewer)),
      Adapter: {
        getMetaData: vi.fn((_viewer, key) =>
          key === "sceneId" ? Primitive_option.some(currentSceneId) : undefined
        ),
      },
    };
  });

  vi.mock('../../src/utils/Logger.bs.js', () => ({
    debug: vi.fn(),
    info: vi.fn(),
    error: vi.fn(),
    initialized: vi.fn(),
    setOperationId: vi.fn(),
    startOperation: vi.fn(),
    endOperation: vi.fn(),
    getErrorDetails: () => ["", ""],
    castToJson: (obj) => obj
  }));

  vi.mock('../../src/systems/TeaserRecorderSupport.bs.js', () => ({
    canvasHasPaintedPixels: vi.fn(() => true),
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
    let scene1 = TestUtils.createMockScene(~id="scene1", ~name="Scene 1", ())
    let scene2 = TestUtils.createMockScene(~id="scene2", ~name="Scene 2", ())
    let mockState = TestUtils.createMockState(~scenes=[scene1, scene2], ())
    mockGetState->mockReturnValue(mockState)

    // Setup Viewer
    let _ = %raw(`global.window.pannellumViewer.getScene = () => "scene1"`)
    setCurrentViewerSceneId("scene1")
    mockCanvasHasPaintedPixels->mockReturnValue(true)
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
      standardConfig,
      ~getState=AppStateBridge.getState,
      ~dispatch=AppStateBridge.dispatch,
    )
    await advanceTimersByTimeAsync(2000)
    await p

    // Verify Dispatch
    let dispatchCalls = %raw(`mockDispatch.mock.calls`)
    t->expect(Array.length(dispatchCalls))->Expect.Int.toBeGreaterThan(0)

    // Verify active viewer orientation was set through ViewerSystem path
    let setYawCalls = %raw(`mockViewerSetYaw.mock.calls`)
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
    setCurrentViewerSceneId("scene2")

    let p = transitionToNextShot(
      0,
      step,
      "fast",
      standardConfig,
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

  test("getManifestStateAt applies wait->motion->blink->crossfade timeline", t => {
    let shot1: Types.motionShot = {
      sceneId: "scene1",
      arrivalPose: {yaw: 0.0, pitch: 0.0, hfov: 90.0},
      animationSegments: [
        {
          startYaw: 0.0,
          endYaw: 10.0,
          startPitch: 0.0,
          endPitch: 0.0,
          startHfov: 90.0,
          endHfov: 90.0,
          easing: "linear",
          durationMs: 1000,
        },
      ],
      transitionOut: Some({type_: "crossfade", durationMs: 300}),
      pathData: None,
      waitBeforePanMs: 100,
      blinkAfterPanMs: 200,
    }

    let shot2: Types.motionShot = {
      sceneId: "scene2",
      arrivalPose: {yaw: 50.0, pitch: 5.0, hfov: 90.0},
      animationSegments: [],
      transitionOut: None,
      pathData: None,
      waitBeforePanMs: 0,
      blinkAfterPanMs: 0,
    }

    let manifest: Types.motionManifest = {
      version: "motion-spec-v1",
      fps: 60,
      canvasWidth: 1920,
      canvasHeight: 1080,
      includeIntroPan: false,
      shots: [shot1, shot2],
    }

    let duringWait = getManifestStateAt(manifest, 50.0)
    t->expect(duringWait.sceneId)->Expect.toBe("scene1")
    t->expect(duringWait.pose.yaw)->Expect.toBe(0.0)
    t->expect(duringWait.fadeOpacity)->Expect.toBe(0.0)

    let duringMotion = getManifestStateAt(manifest, 600.0)
    t->expect(duringMotion.sceneId)->Expect.toBe("scene1")
    t->expect(duringMotion.pose.yaw)->Expect.Float.toBeGreaterThan(0.0)
    t->expect(duringMotion.fadeOpacity)->Expect.toBe(0.0)

    let duringBlink = getManifestStateAt(manifest, 1250.0)
    t->expect(duringBlink.sceneId)->Expect.toBe("scene1")
    t->expect(duringBlink.pose.yaw)->Expect.toBe(10.0)
    t->expect(duringBlink.fadeOpacity)->Expect.toBe(0.0)

    let duringTransition = getManifestStateAt(manifest, 1400.0)
    t->expect(duringTransition.sceneId)->Expect.toBe("scene2")
    t->expect(duringTransition.pose.yaw)->Expect.toBe(50.0)
    t->expect(duringTransition.fadeOpacity)->Expect.Float.toBeGreaterThan(0.0)
    t->expect(duringTransition.fadeOpacity)->Expect.Float.toBeLessThan(1.0)
  })
})
