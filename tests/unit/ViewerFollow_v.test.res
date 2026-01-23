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
})
