open Vitest

describe("ViewerFollow", () => {
  test("updateFollowLoop should stop if followLoopActive is false", t => {
    ViewerState.state := {...ViewerState.state.contents, followLoopActive: false}

    // Setup mock DOM to avoid crashes on getElementById
    let _ = %raw(`
      (function(){ document.body.innerHTML = '<div id="processing-ui" class="hidden"></div>' })()
    `)

    ViewerSystem.Follow.updateFollowLoop()

    t->expect(ViewerState.state.contents.followLoopActive)->Expect.toBe(false)
  })

  test("updateFollowLoop should stop if no viewer", t => {
    ViewerState.state := {...ViewerState.state.contents, followLoopActive: true}
    ViewerSystem.Pool.clearInstance("panorama-a")

    // State with no linking and no hotspots
    let mockState = {
      ...State.initialState,
      isLinking: false,
      scenes: [],
    }
    GlobalStateBridge.setState(mockState)

    ViewerSystem.Follow.updateFollowLoop()

    t->expect(ViewerState.state.contents.followLoopActive)->Expect.toBe(false)
  })

  testAsync("updateFollowLoop should apply movement when linking", async t => {
    // Setup state for linking
    ViewerState.state := {
      ...ViewerState.state.contents,
      followLoopActive: true,
      mouseXNorm: 0.8, // Outside 0.5 deadzone
      mouseYNorm: 0.0, // Inside deadzone
      linkingStartPoint: Nullable.null // No deadzone block
    }

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
    ViewerSystem.Pool.registerInstance("panorama-a", mockViewer)

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

    ViewerSystem.Follow.updateFollowLoop()

    // It should have called setYaw because mouseXNorm is 0.8
    t->expect(yawValue.contents > 0.0)->Expect.toBe(true)
    t->expect(Math.abs(yawValue.contents -. 0.54) < 0.001)->Expect.toBe(true)
    t->expect(pitchValue.contents)->Expect.toBe(0.0)

    // Cleanup
    let _ = %raw(`window.requestAnimationFrame = require('node:timers').setTimeout`)
  })
})
