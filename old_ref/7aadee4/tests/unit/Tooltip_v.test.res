open Vitest
open ReBindings

describe("Tooltip", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render tooltip content when enabled", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <Shadcn.Tooltip.Provider>
        <Tooltip content="Helper Text">
          <button> {React.string("Hover Me")} </button>
        </Tooltip>
      </Shadcn.Tooltip.Provider>,
    )

    await wait(50)

    let text = Dom.getTextContent(container)
    t->expect(String.includes(text, "Helper Text"))->Expect.toBe(true)
    t->expect(String.includes(text, "Hover Me"))->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should not render tooltip content when disabled", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    ReactDOMClient.Root.render(
      root,
      <Shadcn.Tooltip.Provider>
        <Tooltip content="Hidden Text" disabled=true>
          <button> {React.string("Hover Me")} </button>
        </Tooltip>
      </Shadcn.Tooltip.Provider>,
    )

    await wait(50)

    let text = Dom.getTextContent(container)
    t->expect(String.includes(text, "Hidden Text"))->Expect.toBe(false)
    t->expect(String.includes(text, "Hover Me"))->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
