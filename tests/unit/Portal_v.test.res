// @efficiency: infra-adapter
open Vitest
open ReBindings

describe("Portal", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should create portal root and render children", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    let portalId = "test-portal-root"

    // Ensure it doesn't exist before
    let existing = Dom.getElementById(portalId)
    switch Nullable.toOption(existing) {
    | Some(el) => Dom.removeElement(el)
    | None => ()
    }

    ReactDOMClient.Root.render(
      root,
      <Portal id=portalId>
        <div id="portal-child"> {React.string("Inside Portal")} </div>
      </Portal>,
    )

    await wait(100)

    let portalRoot = Dom.getElementById(portalId)
    t->expect(Belt.Option.isSome(Nullable.toOption(portalRoot)))->Expect.toBe(true)

    switch Nullable.toOption(portalRoot) {
    | Some(el) =>
      let child = Dom.querySelector(el, "#portal-child")
      t->expect(Belt.Option.isSome(Nullable.toOption(child)))->Expect.toBe(true)

      switch Nullable.toOption(child) {
      | Some(childEl) => t->expect(Dom.getTextContent(childEl))->Expect.toBe("Inside Portal")
      | None => ()
      }
    | None => ()
    }

    Dom.removeElement(container)
    // Clean up portal root
    switch Nullable.toOption(portalRoot) {
    | Some(el) => Dom.removeElement(el)
    | None => ()
    }
  })

  testAsync("should use existing portal root if available", async t => {
    let portalId = "existing-portal-root"
    let existing = Dom.createElement("div")
    Dom.setId(existing, portalId)
    Dom.appendChild(Dom.documentBody, existing)

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <Portal id=portalId>
        <div id="existing-child"> {React.string("Existing")} </div>
      </Portal>,
    )

    await wait(100)

    let child = Dom.querySelector(existing, "#existing-child")
    t->expect(Belt.Option.isSome(Nullable.toOption(child)))->Expect.toBe(true)

    Dom.removeElement(container)
    Dom.removeElement(existing)
  })
})
