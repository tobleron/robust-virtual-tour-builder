open Vitest

describe("ViewerFollow", () => {
  test("updateFollowLoop should stop if followLoopActive is false", t => {
    ViewerState.state.followLoopActive = false

    // Setup mock DOM to avoid crashes on getElementById
    let _ = %raw(`
      (function(){ document.body.innerHTML = '<div id="processing-ui" class="hidden"></div>' })()
    `)

    ViewerFollow.updateFollowLoop()

    t->expect(ViewerState.state.followLoopActive)->Expect.toBe(false)
  })

  test("updateFollowLoop should stop if no viewer", t => {
    ViewerState.state.followLoopActive = true
    ViewerState.state.viewerA = Nullable.null
    ViewerState.state.activeViewerKey = A

    // State with no linking and no hotspots
    let mockState = {
      ...State.initialState,
      isLinking: false,
      scenes: [],
    }
    GlobalStateBridge.setState(mockState)

    ViewerFollow.updateFollowLoop()

    t->expect(ViewerState.state.followLoopActive)->Expect.toBe(false)
  })

  testAsync("updateFollowLoop should apply movement when linking", async t => {
    // Setup state for linking
    ViewerState.state.followLoopActive = true
    ViewerState.state.activeViewerKey = A
    ViewerState.state.mouseXNorm = 0.8 // Outside 0.5 deadzone
    ViewerState.state.mouseYNorm = 0.0 // Inside deadzone
    ViewerState.state.linkingStartPoint = Nullable.null // No deadzone block

    let mockState = {
      ...State.initialState,
      isLinking: true,
      scenes: [],
    }
    GlobalStateBridge.setState(mockState)

    // Mock Viewer
    let yawValue = ref(0.0)
    let pitchValue = ref(0.0)

    let mockViewer = Obj.magic({
      "getYaw": () => yawValue.contents,
      "getPitch": () => pitchValue.contents,
      "setYaw": (v, _rel) => yawValue := v,
      "setPitch": (v, _rel) => pitchValue := v,
    })
    ViewerState.state.viewerA = Nullable.make(mockViewer)

    // Mock DOM
    let _ = %raw(`
      (function(){ document.body.innerHTML = '<div id="processing-ui" class="hidden"></div>' })()
    `)

    // We need to prevent requestAnimationFrame from looping infinitely in test
    let _ = %raw(`
      (function() {
        global.capturedRaf = null;
        window.requestAnimationFrame = (cb) => {
          global.capturedRaf = cb;
          return 1;
        };
      })()
    `)

    ViewerFollow.updateFollowLoop()

    // It should have called setYaw because mouseXNorm is 0.8
    // getEdgePower(0.8, 0.5) -> (0.8-0.5)/(1.0-0.5) = 0.3/0.5 = 0.6
    // 0.6 * 0.6 = 0.36
    // 0.36 * 1.5 (yawMaxSpeed) = 0.54
    t->expect(yawValue.contents > 0.0)->Expect.toBe(true)
    t->expect(Math.abs(yawValue.contents -. 0.54) < 0.001)->Expect.toBe(true)
    t->expect(pitchValue.contents)->Expect.toBe(0.0)

    // Cleanup
    let _ = %raw(`window.requestAnimationFrame = require('node:timers').setTimeout`) // close enough for cleanup
  })

  testAsync("updateFollowLoop should apply velocity boost", async t => {
    ViewerState.state.followLoopActive = true
    ViewerState.state.activeViewerKey = A
    ViewerState.state.mouseXNorm = 0.8
    ViewerState.state.mouseYNorm = 0.0
    ViewerState.state.mouseVelocityX = 3500.0 // Max boost (1.5)
    ViewerState.state.linkingStartPoint = Nullable.null

    let mockState = {
      ...State.initialState,
      isLinking: true,
      scenes: [],
    }
    GlobalStateBridge.setState(mockState)

    let yawValue = ref(0.0)
    let mockViewer = Obj.magic({
      "getYaw": () => yawValue.contents,
      "setYaw": (v, _rel) => yawValue := v,
    })
    ViewerState.state.viewerA = Nullable.make(mockViewer)

    let _ = %raw(`
      (function() { window.requestAnimationFrame = (cb) => { return 1; }; })()
    `)

    ViewerFollow.updateFollowLoop()

    // Normal speed was 0.54
    // Boost: (3500 - 500) / 3000 = 1.0 boost factor
    // Total speed multiplier: 1.0 + 1.0 = 2.0
    // 0.54 * 2.0 = 1.08
    t->expect(Math.abs(yawValue.contents -. 1.08) < 0.001)->Expect.toBe(true)
  })
})
