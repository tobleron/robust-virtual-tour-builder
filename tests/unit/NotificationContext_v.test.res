open Vitest
open ReBindings

describe("NotificationContext", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render notification when ShowNotification is dispatched", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationContext />)

    await wait(50)

    NotificationContext.notify("Test Notification", #Success)

    await wait(50)

    let toast = Dom.querySelector(container, ".toast")
    t->expect(Belt.Option.isSome(Nullable.toOption(toast)))->Expect.toBe(true)

    switch Nullable.toOption(toast) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(String.includes(text, "Test Notification"))->Expect.toBe(true)
    | None => ()
    }

    Dom.removeElement(container)
  })
})
