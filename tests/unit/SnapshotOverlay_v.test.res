// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("SnapshotOverlay", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render static overlay div", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <SnapshotOverlay />)

    await wait(50)

    let overlay = Dom.getElementById("viewer-snapshot-overlay")
    t->expect(Nullable.toOption(overlay)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
