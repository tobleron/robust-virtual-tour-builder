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
    preCalculatedSnapshot: None,
  }

  let defaultHotspot: hotspot = {
    linkId: "",
    yaw: 0.0,
    pitch: 0.0,
    target: "",
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

    let hotspot: hotspot = {
      ...defaultHotspot,
      linkId: "hs1",
      target: "Target",
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
    switch Nullable.toOption(deleteBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.RemoveHotspot(0, 5)))

    Dom.removeElement(container)
  })

  testAsync("should dispatch UpdateSceneMetadata for auto-forward toggle", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let targetScene = {
      ...defaultScene,
      id: "s2",
      name: "Target",
      isAutoForward: false,
    }

    let mockState = {
      ...State.initialState,
      activeIndex: 0,
      scenes: [{...defaultScene, id: "s1", name: "Source"}, targetScene],
    }
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    let hotspot: hotspot = {
      ...defaultHotspot,
      linkId: "hs1",
      target: "Target",
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

    let autoBtn = Dom.querySelector(container, "button[title='Toggle Auto-Forward']")
    switch Nullable.toOption(autoBtn) {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    switch lastAction.contents {
    | Some(UpdateSceneMetadata(idx, metadata)) =>
      t->expect(idx)->Expect.toBe(1)
      t->expect(Obj.magic(metadata)["isAutoForward"])->Expect.toBe(true)
    | _ => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })
})
