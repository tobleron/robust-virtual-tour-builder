/* tests/unit/ModalContext_v.test.res */
open Vitest
open ReBindings
open EventBus

describe("ModalContext", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render modal when ShowModal is dispatched and close it", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ModalContext />)

    await wait(50)

    let config: modalConfig = {
      title: "Test Modal",
      description: Some("Test Description"),
      icon: Some("success"),
      content: None,
      buttons: [],
      allowClose: Some(true),
      onClose: None,
      className: None,
    }

    EventBus.dispatch(ShowModal(config))
    await wait(50)

    let title = Dom.getElementById("modal-title")
    t->expect(Nullable.toOption(title)->Belt.Option.isSome)->Expect.toBe(true)
    t->expect(Dom.getTextContent(Nullable.getUnsafe(title)))->Expect.toBe("Test Modal")

    EventBus.dispatch(CloseModal)
    await wait(50)

    let titleAfter = Dom.getElementById("modal-title")
    t->expect(Nullable.toOption(titleAfter)->Belt.Option.isNone)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should trigger button click and autoClose", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ModalContext />)

    await wait(50)

    let clicked = ref(false)
    let config: modalConfig = {
      title: "Confirm",
      description: None,
      icon: None,
      content: None,
      buttons: [
        {
          label: "OK",
          class_: "btn-ok",
          onClick: () => clicked := true,
          autoClose: Some(true),
        },
      ],
      allowClose: Some(true),
      onClose: None,
      className: None,
    }

    EventBus.dispatch(ShowModal(config))
    await wait(50)

    let okBtn = Dom.querySelector(container, ".btn-ok")
    switch Nullable.toOption(okBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    t->expect(clicked.contents)->Expect.toBe(true)
    await wait(50)

    // Should be closed due to autoClose
    let title = Dom.getElementById("modal-title")
    t->expect(Nullable.toOption(title)->Belt.Option.isNone)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should close on Escape key", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ModalContext />)

    await wait(50)

    let config: modalConfig = {
      title: "Escape Me",
      description: None,
      icon: None,
      content: None,
      buttons: [],
      allowClose: Some(true),
      onClose: None,
      className: None,
    }

    EventBus.dispatch(ShowModal(config))
    await wait(100) // Longer wait for initial focus timeout

    // Dispatch Escape key event on window
    let event = %raw(`new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })`)
    let _ = %raw(`(ev) => window.dispatchEvent(ev)`)(event)

    await wait(50)
    let title = Dom.getElementById("modal-title")
    t->expect(Nullable.toOption(title)->Belt.Option.isNone)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should trigger first button on Enter key", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <ModalContext />)

    let clicked = ref(false)
    let config: modalConfig = {
      title: "Enter Me",
      description: None,
      icon: None,
      content: None,
      buttons: [
        {
          label: "Enter",
          class_: "btn-enter",
          onClick: () => clicked := true,
          autoClose: Some(true),
        },
      ],
      allowClose: Some(true),
      onClose: None,
      className: None,
    }

    EventBus.dispatch(ShowModal(config))
    await wait(100)

    let event = %raw(`new KeyboardEvent('keydown', { key: 'Enter', bubbles: true })`)
    let _ = %raw(`(ev) => window.dispatchEvent(ev)`)(event)

    await wait(50)
    t->expect(clicked.contents)->Expect.toBe(true)

    let title = Dom.getElementById("modal-title")
    t->expect(Nullable.toOption(title)->Belt.Option.isNone)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
