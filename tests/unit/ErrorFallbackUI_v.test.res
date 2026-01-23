open Vitest
open ReBindings

describe("ErrorFallbackUI", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render error fallback UI", async t => {
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

    let btn = Dom.querySelector(container, ".error-fallback-btn")
    t->expect(Belt.Option.isSome(Nullable.toOption(btn)))->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
