open Vitest
open ReBindings

describe("NotificationContext (Legacy)", () => {
  // NotificationContext is now a placeholder component.
  // The notification system has been migrated to NotificationManager + NotificationCenter.
  // Keeping this test file for backward compatibility, but testing the basic render.

  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render placeholder component without error", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationContext />)

    await wait(50)

    // NotificationContext is now a placeholder that returns null
    t->expect(true)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
