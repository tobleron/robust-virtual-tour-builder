// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("ErrorFallbackUI", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render error fallback UI with correct content", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ErrorFallbackUI />)

    await wait(50)

    let title = Dom.querySelector(container, ".error-fallback-title")
    t->expect(Belt.Option.isSome(Nullable.toOption(title)))->Expect.toBe(true)

    switch Nullable.toOption(title) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("Application Error")
    | None => ()
    }

    let message = Dom.querySelector(container, ".error-fallback-message")
    switch Nullable.toOption(message) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(String.includes(text, "An unexpected error occurred"))->Expect.toBe(true)
    | None => t->expect(true)->Expect.toBe(false)
    }

    let btn = Dom.querySelector(container, ".error-fallback-btn")
    t->expect(Belt.Option.isSome(Nullable.toOption(btn)))->Expect.toBe(true)

    switch Nullable.toOption(btn) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("Reload Application")
    | None => ()
    }

    Dom.removeElement(container)
  })

  testAsync("should trigger reload action when button clicked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let reloadCalled = ref(false)
    let onReload = () => {
      reloadCalled := true
    }

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ErrorFallbackUI onReload />)

    await wait(50)

    let btn = Dom.querySelector(container, ".error-fallback-btn")

    switch Nullable.toOption(btn) {
    | Some(el) => Dom.click(el)
    | None => t->expect(true)->Expect.toBe(false)
    }

    await wait(10)

    t->expect(reloadCalled.contents)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
