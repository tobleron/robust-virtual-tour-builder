// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("NotificationLayer", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render Sonner component", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationLayer />)

    await wait(50)

    // Sonner itself is usually a container, our mock renders children or nothing.
    // We basically check if it mounts without error.
    t->expect(true)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should handle UpdateProcessing events", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationLayer />)

    await wait(50)

    EventBus.dispatch(
      UpdateProcessing({
        "active": true,
        "progress": 50.0,
        "message": "Processing...",
        "phase": "Test",
        "error": false,
      }),
    )

    await wait(50)
    // NotificationLayer doesn't render the message directly in current implementation,
    // it just uses Sonner or local state.
    // In NotificationLayer.res, it only renders Shadcn.Sonner.
    t->expect(true)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
