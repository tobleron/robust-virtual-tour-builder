// @efficiency: infra-adapter
open Vitest
open ReBindings
open ViewerState
open CursorPhysics

describe("CursorPhysics", () => {
  test("calculateVelocity updates viewer state", t => {
    // Reset state
    ViewerState.state := {
      ...ViewerState.state.contents,
      lastMoveX: 100.0,
      lastMoveY: 100.0,
      lastMoveTime: Date.now() -. 50.0, // 50ms ago
      mouseVelocityX: 0.0,
      mouseVelocityY: 0.0,
    }

    calculateVelocity(150.0, 120.0)

    // Check if velocities were updated (they should be non-zero)
    t->expect(ViewerState.state.contents.mouseVelocityX != 0.0)->Expect.toBe(true)
    t->expect(ViewerState.state.contents.mouseVelocityY != 0.0)->Expect.toBe(true)
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
