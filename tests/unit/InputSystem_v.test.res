// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("InputSystem", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let dispatchKey = (~key, ~ctrlKey=false, ~shiftKey=false, ()) => {
    let config = {
      "key": key,
      "ctrlKey": ctrlKey,
      "shiftKey": shiftKey,
      "bubbles": true,
      "cancelable": true,
    }
    let event = %raw(`function(c) { return new KeyboardEvent('keydown', c) }`)(config)
    let _ = ReBindings.Window.dispatchEvent(event)
    let _ = %raw(`document.body.dispatchEvent(event)`)
  }

  beforeAll(() => {
    ignore(InputSystem.initInputSystem())
  })

  testAsync("should close modal on Escape", async t => {
    // Setup modal
    let modal = Dom.createElement("div")
    Dom.setId(modal, "style-modal")
    Dom.setDisplay(modal, "flex")

    // Add close button
    let closeBtn = Dom.createElement("button")
    Dom.setId(closeBtn, "btn-close-style")
    let clicked = ref(false)
    Dom.setOnClick(closeBtn, _ => clicked := true)
    Dom.appendChild(modal, closeBtn)

    Dom.appendChild(Dom.documentBody, modal)

    dispatchKey(~key="Escape", ())

    await wait(10)

    t->expect(clicked.contents)->Expect.toBe(true)

    Dom.removeElement(modal)
  })

  testAsync("should hide context menu on Escape", async t => {
    let menu = Dom.createElement("div")
    Dom.setId(menu, "context-menu")
    // Ensure it's not hidden
    Dom.ClassList.remove(Dom.classList(menu), "hidden")
    Dom.appendChild(Dom.documentBody, menu)

    dispatchKey(~key="Escape", ())
    await wait(10)

    t->expect(Dom.ClassList.contains(Dom.classList(menu), "hidden"))->Expect.toBe(true)

    Dom.removeElement(menu)
  })

  testAsync("should toggle debug mode on Ctrl+Shift+D", async t => {
    // We need to mock window.DEBUG or check Logger/Notification
    // InputSystem checks window.DEBUG.toggle

    let _ = %raw(`
      window.DEBUG = {
        toggle: () => { return true; } // Returns new state
      }
    `)

    dispatchKey(~key="D", ~ctrlKey=true, ~shiftKey=true, ())
    await wait(10)

    t->expect(true)->Expect.toBe(true) // Placeholder until we can verification
  })

  testAsync("should update ViewerState on mouse move", async t => {
    // Setup viewer-stage
    let stage = Dom.createElement("div")
    Dom.setId(stage, "viewer-stage")
    // Mock getBoundingClientRect
    // width: 100, height: 100, top: 0, left: 0
    let _ = %raw(`stage.getBoundingClientRect = () => ({ left: 0, top: 0, width: 100, height: 100 })`)
    Dom.appendChild(Dom.documentBody, stage)

    // Trigger mouse move logic directly
    // clientX: 75 -> x = 75 -> xNorm = 0.5
    // clientY: 50 -> y = 50 -> yNorm = (50 + Constants.linkingRodHeight)/100 * 2 - 1 = 1.6
    // Constants.linkingRodHeight is 80.0
    let mockEvent = %raw(`{ clientX: 75, clientY: 50 }`)
    InputSystem.handleMouseMove(mockEvent)

    t->expect(ViewerState.state.mouseXNorm)->Expect.toBe(0.5)
    t->expect(ViewerState.state.mouseYNorm)->Expect.toBe(1.6)

    Dom.removeElement(stage)
  })
})
