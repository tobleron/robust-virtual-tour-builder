open Vitest
open ReBindings

module Thrower = {
  @react.component
  let make = (~shouldThrow) => {
    if shouldThrow {
      let _ = %raw(`(function(){ throw new Error("Intentional Test Error") })()`)
    }
    <div> {React.string("Safe Content")} </div>
  }
}

describe("RemaxErrorBoundary", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should render children when no error", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <RemaxErrorBoundary>
        <Thrower shouldThrow=false />
      </RemaxErrorBoundary>,
    )

    await wait(50)

    let content = Dom.getTextContent(container)
    t->expect(String.includes(content, "Safe Content"))->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should render fallback when child throws", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    // Silence console.error for expected test error
    let _ = %raw(`vi.spyOn(console, 'error').mockImplementation(() => {})`)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <RemaxErrorBoundary>
        <Thrower shouldThrow=true />
      </RemaxErrorBoundary>,
    )

    await wait(100)

    // Check for ErrorFallbackUI content
    let content = Dom.getTextContent(container)
    t->expect(String.includes(content, "Application Error"))->Expect.toBe(true)

    Dom.removeElement(container)
    let _ = %raw(`console.error.mockRestore()`)
  })
})
