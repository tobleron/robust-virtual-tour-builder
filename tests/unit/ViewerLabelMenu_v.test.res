open Vitest
open ReBindings

describe("ViewerLabelMenu", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render label menu trigger button", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ViewerLabelMenu scenesLoaded=true isLinking=false />)

    await wait(50)

    let hashBtn = Dom.querySelector(container, "button")
    t->expect(Nullable.toOption(hashBtn)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
