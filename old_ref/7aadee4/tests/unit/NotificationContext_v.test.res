/* tests/unit/NotificationContext_v.test.res */
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
    t->expect(Nullable.toOption(toast)->Belt.Option.isSome)->Expect.toBe(true)

    switch Nullable.toOption(toast) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text->String.includes("Test Notification"))->Expect.toBe(true)
      t->expect(Dom.classList(el)->Dom.ClassList.contains("success"))->Expect.toBe(true)
    | None => ()
    }

    Dom.removeElement(container)
  })

  testAsync("should handle different notification types", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationContext />)

    await wait(50)

    NotificationContext.notify("Error", #Error)
    NotificationContext.notify("Warning", #Warning)
    NotificationContext.notify("Info", #Info)

    await wait(50)

    let errorToast = Dom.querySelector(container, ".toast.error")
    let warningToast = Dom.querySelector(container, ".toast.warning")
    let infoToast = Dom.querySelector(container, ".toast") // Info has no extra type class, just 'toast show'

    t->expect(Nullable.toOption(errorToast)->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(Nullable.toOption(warningToast)->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(Nullable.toOption(infoToast)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should auto-dismiss notifications after timeout", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <NotificationContext />)

    await wait(50)

    NotificationContext.notify("Toast", #Info)

    await wait(50)
    let toast = Dom.querySelector(container, ".toast")
    t->expect(Nullable.toOption(toast)->Belt.Option.isSome)->Expect.toBe(true)

    // Wait for timeout (3500ms + buffer)
    await wait(3600)

    let toastAfter = Dom.querySelector(container, ".toast")
    t->expect(Nullable.toOption(toastAfter)->Belt.Option.isNone)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
