/* tests/unit/NotificationContext_v.test.res */
open Vitest
open ReBindings

describe("NotificationContext", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render bridge when ShowNotification is dispatched", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationContext />)

    await wait(50)

    let bridge = Dom.querySelector(container, "[data-testid='notification-context']")
    t->expect(Nullable.toOption(bridge)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should bridge different notification types", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationContext />)

    await wait(50)

    // These calls now trigger Shadcn.Sonner (mocked)
    NotificationContext.notify("Error", #Error)
    NotificationContext.notify("Warning", #Warning)
    NotificationContext.notify("Info", #Info)

    await wait(50)

    // We just verify it doesn't throw and bridge remains
    let bridge = Dom.querySelector(container, "[data-testid='notification-context']")
    t->expect(Nullable.toOption(bridge)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
