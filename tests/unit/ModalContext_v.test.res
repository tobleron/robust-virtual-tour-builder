open Vitest
open ReBindings
open EventBus

describe("ModalContext", () => {
  // Helper to wait for React updates
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render modal when ShowModal is dispatched", async t => {
    // Setup container
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    // Render ModalContext
    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ModalContext />)

    // Wait for mount
    await wait(50)

    // Dispatch ShowModal
    let config: modalConfig = {
      title: "Test Modal",
      description: Some("Test Description"),
      icon: None,
      content: None,
      buttons: [],
      allowClose: Some(true),
      onClose: None,
      className: None,
    }

    EventBus.dispatch(ShowModal(config))

    // Wait for update
    await wait(50)

    // Assert presence
    let title = Dom.getElementById("modal-title")
    t->expect(Belt.Option.isSome(Nullable.toOption(title)))->Expect.toBe(true)

    // Dispatch CloseModal
    EventBus.dispatch(CloseModal)

    // Wait for update
    await wait(50)

    // Assert absence
    let titleAfter = Dom.getElementById("modal-title")
    t->expect(Belt.Option.isNone(Nullable.toOption(titleAfter)))->Expect.toBe(true)

    // Cleanup
    Dom.removeElement(container)
  })
})
