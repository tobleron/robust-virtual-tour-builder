// @efficiency: infra-adapter
open Vitest
open ReBindings

@module("vitest") @scope("vi") external useFakeTimers: unit => unit = "useFakeTimers"
@module("vitest") @scope("vi") external useRealTimers: unit => unit = "useRealTimers"
@module("vitest") @scope("vi") external advanceTimersByTime: int => unit = "advanceTimersByTime"
@module("vitest") @scope("vi") external setSystemTime: float => unit = "setSystemTime"

module Act = {
  @module("react") external act: (unit => promise<unit>) => promise<unit> = "act"
}

module TestComponent = {
  @react.component
  let make = () => {
    let fileInputRef = React.useRef(Nullable.null)
    let procState = UseSidebarProcessing.useProcessingState(fileInputRef)

    <div dataTestId="proc-state">
      {
        let json = JSON.Encode.object(
          Dict.fromArray([
            ("active", JSON.Encode.bool(procState["active"])),
            ("message", JSON.Encode.string(procState["message"])),
          ]),
        )
        React.string(JSON.stringify(json))
      }
    </div>
  }
}

describe("UseSidebarProcessing", () => {
  beforeEach(() => {
    useFakeTimers()
    setSystemTime(1000.0)
    OperationLifecycle.reset()
  })

  afterEach(() => {
    useRealTimers()
  })

  testAsync("should hide operation before threshold and show after", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    await Act.act(
      async () => {
        ReactDOMClient.Root.render(root, <TestComponent />)
      },
    )

    // Start operation with 500ms threshold
    ReBindings.Window.setTimeout(
      () => {
        let _ = OperationLifecycle.start(~type_=OperationLifecycle.Upload, ~visibleAfterMs=500, ())
      },
      0,
    )->ignore

    // Process the start
    await Act.act(
      async () => {
        advanceTimersByTime(10) // 1010ms. Elapsed 10ms. < 500ms.
      },
    )

    let el = Dom.querySelector(container, "[data-testid='proc-state']")
    let content = Dom.getTextContent(Nullable.getUnsafe(el))
    t->expect(content->String.includes("\"active\":false"))->Expect.toBe(true)

    // Advance to 600ms elapsed
    await Act.act(
      async () => {
        advanceTimersByTime(600) // 1610ms. Elapsed 610ms. > 500ms.
      },
    )

    let content2 = Dom.getTextContent(Nullable.getUnsafe(el))
    t->expect(content2->String.includes("\"active\":true"))->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should not show short operation if completed before threshold", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    await Act.act(
      async () => {
        ReactDOMClient.Root.render(root, <TestComponent />)
      },
    )

    let opId = ref("")
    ReBindings.Window.setTimeout(
      () => {
        opId := OperationLifecycle.start(~type_=OperationLifecycle.Upload, ~visibleAfterMs=500, ())
      },
      0,
    )->ignore

    // Start
    await Act.act(
      async () => {
        advanceTimersByTime(10)
      },
    )

    let el = Dom.querySelector(container, "[data-testid='proc-state']")
    t
    ->expect(Dom.getTextContent(Nullable.getUnsafe(el))->String.includes("\"active\":false"))
    ->Expect.toBe(true)

    // Complete at 200ms elapsed
    ReBindings.Window.setTimeout(
      () => {
        OperationLifecycle.complete(opId.contents, ~result="Done", ())
      },
      0,
    )->ignore

    await Act.act(
      async () => {
        advanceTimersByTime(200) // 1210ms. Elapsed 210ms.
      },
    )

    // Should still be inactive because duration (210) < 500
    t
    ->expect(Dom.getTextContent(Nullable.getUnsafe(el))->String.includes("\"active\":false"))
    ->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should not surface failed non-active operation in processing banner", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)

    await Act.act(
      async () => {
        ReactDOMClient.Root.render(root, <TestComponent />)
      },
    )

    let opId = ref("")
    ReBindings.Window.setTimeout(
      () => {
        opId := OperationLifecycle.start(~type_=OperationLifecycle.Upload, ~visibleAfterMs=500, ())
      },
      0,
    )->ignore

    // Start
    await Act.act(
      async () => {
        advanceTimersByTime(10)
      },
    )

    // Fail immediately
    ReBindings.Window.setTimeout(
      () => {
        OperationLifecycle.fail(opId.contents, "Oops")
      },
      0,
    )->ignore

    await Act.act(
      async () => {
        advanceTimersByTime(10)
      },
    )

    let el = Dom.querySelector(container, "[data-testid='proc-state']")
    let content = Dom.getTextContent(Nullable.getUnsafe(el))

    // Current behavior: hook only considers Active/Paused ops for banner visibility.
    t->expect(content->String.includes("\"active\":false"))->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
