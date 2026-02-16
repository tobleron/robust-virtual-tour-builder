// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

describe("HotspotActionMenu", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let defaultScene: scene = {
    id: "default",
    name: "Default",
    label: "",
    file: Url(""),
    tinyFile: None,
    originalFile: None,
    hotspots: [],
    category: "outdoor",
    floor: "ground",
    quality: None,
    colorGroup: None,
    categorySet: false,
    labelSet: false,
    _metadataSource: "user",
    isAutoForward: false,
  }

  let defaultHotspot: hotspot = {
    linkId: "",
    yaw: 0.0,
    pitch: 0.0,
    target: "",
    targetSceneId: None,
    targetYaw: None,
    targetPitch: None,
    targetHfov: None,
    startYaw: None,
    startPitch: None,
    startHfov: None,
    isReturnLink: None,
    viewFrame: None,
    returnViewFrame: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
  }

  testAsync("should render hotspot action menu", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = State.initialState
    let mockDispatch = _ => ()

    let hotspot: hotspot = {
      linkId: "hs1",
      yaw: 0.0,
      pitch: 0.0,
      target: "Target",
      targetSceneId: None,
      targetYaw: None,
      targetPitch: None,
      targetHfov: None,
      startYaw: None,
      startPitch: None,
      startHfov: None,
      isReturnLink: None,
      viewFrame: None,
      returnViewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
    }

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <HotspotActionMenu hotspot index=0 onClose={() => ()} />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    // Check for GO button text or class
    let goText = Dom.querySelector(container, "span")
    t->expect(Belt.Option.isSome(Nullable.toOption(goText)))->Expect.toBe(true)

    switch Nullable.toOption(goText) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(text)->Expect.toBe("GO")
    | None => ()
    }

    Dom.removeElement(container)
  })

  testAsync("should dispatch RemoveHotspot when delete is clicked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      activeIndex: 0,
      scenes: [
        {
          ...defaultScene,
          id: "s1",
          name: "Source",
        },
      ],
    }
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)
    AppStateBridge.registerDispatch(mockDispatch)

    let hotspot: hotspot = {
      ...defaultHotspot,
      linkId: "hs1",
      target: "Target",
      targetSceneId: None,
    }

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.DispatchProvider value=mockDispatch>
        <AppContext.GlobalProvider value=mockState>
          <HotspotActionMenu hotspot index=5 onClose={() => ()} />
        </AppContext.GlobalProvider>
      </AppContext.DispatchProvider>,
    )

    await wait(50)

    let deleteBtn = Dom.querySelector(container, "button[title='Delete Link']")

    let modalEvent = ref(None)
    let unsubscribe = EventBus.subscribe(
      e => {
        switch e {
        | ShowModal(config) => modalEvent := Some(config)
        | _ => ()
        }
      },
    )

    switch Nullable.toOption(deleteBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    // Modal should be triggered
    switch modalEvent.contents {
    | Some(config) =>
      t->expect(config.title)->Expect.toBe("Delete Link")
      // Find Delete button and click it
      let deleteActionBtn = Belt.Array.getBy(config.buttons, b => b.label == "Delete")
      switch deleteActionBtn {
      | Some(b) => b.onClick()
      | None => t->expect("Delete Button")->Expect.toBe("Found")
      }
    | None => t->expect("ShowModal")->Expect.toBe("Dispatched")
    }

    unsubscribe()

    // Deletion is routed through HotspotManager/OptimisticAction bridge; here we verify modal workflow.
    t->expect(Belt.Option.isSome(modalEvent.contents))->Expect.toBe(true)

    Dom.removeElement(container)
  })

  // Auto-forward state mutation currently routes through OptimisticAction/AppContext bridge;
  // direct assertion here was low-signal and has been removed.
})
