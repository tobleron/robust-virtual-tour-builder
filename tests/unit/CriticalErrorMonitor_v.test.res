// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

module WrappedMonitor = {
  @react.component
  let make = (~mockState: Types.state, ~mockDispatch: Actions.action => unit, ~children) => {
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
      appMode: mockState.appMode,
    }

    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.UiSliceProvider value=uiSlice> {children} </AppContext.UiSliceProvider>
    </AppContext.DispatchProvider>
  }
}

describe("CriticalErrorMonitor", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let loadMonitor = async () => {
    let m = await %raw(`import('../../src/components/CriticalErrorMonitor.bs.js')`)
    m["make"]
  }

  testAsync("should dispatch ShowModal on CriticalError state", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      appMode: SystemBlocking(CriticalError("Test Critical Error")),
    }
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)

    let monitorCmp = await loadMonitor()

    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedMonitor mockState mockDispatch>
        {React.createElement(monitorCmp, Object.make())}
      </WrappedMonitor>,
    )

    await wait(100)
    unsubscribe()

    switch receivedConfig.contents {
    | Some(config) =>
      t->expect(config.title)->Expect.toBe("Critical Error")
      t->expect(config.description)->Expect.toBe(Some("Test Critical Error"))
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })

  testAsync("should not dispatch ShowModal if not in CriticalError state", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    }
    let mockDispatch = _ => ()
    AppStateBridge.registerDispatch(mockDispatch)

    let monitorCmp = await loadMonitor()

    let receivedConfig = ref(None)
    let unsubscribe = EventBus.subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedConfig := Some(config)
        | _ => ()
        }
      },
    )

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedMonitor mockState mockDispatch>
        {React.createElement(monitorCmp, Object.make())}
      </WrappedMonitor>,
    )

    await wait(100)
    unsubscribe()

    t->expect(receivedConfig.contents)->Expect.toBe(None)

    Dom.removeElement(container)
  })
})
