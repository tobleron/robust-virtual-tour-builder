open Vitest
open ReBindings
open CursorPhysics

describe("CursorPhysics", () => {
  test("calculateVelocity updates viewer state", t => {
    // We need to mock ViewerState or ensure it's in a known state
    ViewerState.state.lastMoveX = 100.0
    ViewerState.state.lastMoveY = 100.0
    ViewerState.state.lastMoveTime = Date.now() -. 50.0 // 50ms ago
    ViewerState.state.mouseVelocityX = 0.0
    ViewerState.state.mouseVelocityY = 0.0

    calculateVelocity(150.0, 120.0)

    // Check if velocities were updated (they should be non-zero)
    t->expect(ViewerState.state.mouseVelocityX != 0.0)->Expect.toBe(true)
    t->expect(ViewerState.state.mouseVelocityY != 0.0)->Expect.toBe(true)
  })

  test("updateRodPosition handles guide visibility", t => {
    let _ = %raw(`
      document.body.innerHTML = '<div id="cursor-guide"></div>'
    `)

    updateRodPosition(100.0, 200.0, true)

    let guide = Dom.getElementById("cursor-guide")
    switch Nullable.toOption(guide) {
    | Some(g) =>
      t
      ->expect(g->Dom.getStyle->Dom.getPropertyValue("transform"))
      ->Expect.toEqual("translate(100px, 200px)")
    | None => t->expect(true)->Expect.toBe(false)
    }

    updateRodPosition(100.0, 200.0, false)
    // Check if display is set to none (note the !important in the code which might make getProperty tricky in a mock Dom)
    // but in jsdom it should work.
  })
})
