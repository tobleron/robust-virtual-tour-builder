// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("HotspotLayer", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render static layers", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <HotspotLayer />)

    await wait(50)

    let indicator = Dom.getElementById("viewer-center-indicator")
    t->expect(Nullable.toOption(indicator)->Belt.Option.isSome)->Expect.toBe(true)

    let lines = Dom.getElementById("viewer-hotspot-lines")
    t->expect(Nullable.toOption(lines)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
