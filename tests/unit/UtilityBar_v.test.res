// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

module WrappedUtilityBar = {
  @react.component
  let make = (
    ~scenesLoaded,
    ~isLinking,
    ~simActive,
    ~currentJourneyId,
    ~isTeasing=false,
    ~mockDispatch,
  ) => {
    let scene1 = {
      id: "s1",
      name: "Scene 1",
      label: "Living Room",
      file: Url("test.webp"),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "indoor",
      floor: "ground",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 0,
    }
    let mockState = TestUtils.createMockState(
      ~scenes=[scene1],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
      movingHotspot: mockState.movingHotspot,
      appMode: mockState.appMode,
      logo: mockState.logo,
      preloadingSceneIndex: mockState.preloadingSceneIndex,
    }

    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.GlobalProvider value=mockState>
        <AppContext.UiSliceProvider value=uiSlice>
          <UtilityBar scenesLoaded isLinking simActive currentJourneyId isTeasing />
        </AppContext.UiSliceProvider>
      </AppContext.GlobalProvider>
    </AppContext.DispatchProvider>
  }
}

describe("UtilityBar", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  testAsync("should handle Plus/X button click to toggle linking", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let _ = %raw(`
      (function() {
        window.pannellumViewer = {
          getYaw: () => 45.0,
          setPitch: function() {},
          setYaw: function() {},
          getPitch: () => 0.0,
          getHfov: () => 90.0
        };
      })()
    `)
    ViewerSystem.Pool.pool := [
        {
          id: "primary-a",
          containerId: "panorama-a",
          status: #Active,
          instance: None,
          cleanupTimeout: None,
        },
      ]
    let viewer = %raw(`window.pannellumViewer`)
    ViewerSystem.Pool.registerInstance("panorama-a", viewer)

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedUtilityBar
        scenesLoaded=true isLinking=false simActive=false currentJourneyId=0 mockDispatch
      />,
    )

    await wait(50)

    let buttons = Dom.querySelectorAll(container, "button")
    let plusBtn = Belt.Array.get(JsHelpers.from(buttons), 0)->Belt.Option.getExn

    Dom.click(plusBtn)

    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.StartLinking(None)))

    // Now test StopLinking
    ReactDOMClient.Root.render(
      root,
      <WrappedUtilityBar
        scenesLoaded=true isLinking=true simActive=false currentJourneyId=0 mockDispatch
      />,
    )

    await wait(50)

    let buttons2 = Dom.querySelectorAll(container, "button")
    let plusBtn2 = Belt.Array.get(JsHelpers.from(buttons2), 0)->Belt.Option.getExn
    Dom.click(plusBtn2)
    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.StopLinking))

    Dom.removeElement(container)
  })

  testAsync("should handle Play/Square button click to toggle autopilot", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedUtilityBar
        scenesLoaded=true isLinking=false simActive=false currentJourneyId=42 mockDispatch
      />,
    )

    await wait(50)

    let buttons = Dom.querySelectorAll(container, "button")
    let playBtn = Belt.Array.get(JsHelpers.from(buttons), 1)->Belt.Option.getExn

    Dom.click(playBtn)

    switch lastAction.contents {
    | Some(Actions.Batch(actions)) => {
        let hasStart = actions->Belt.Array.some(
          action =>
            switch action {
            | Actions.StartAutoPilot(42, false) => true
            | _ => false
            },
        )
        t->expect(hasStart)->Expect.toBe(true)
      }
    | _ => t->expect(false)->Expect.toBe(true)
    }

    // Now test StopAutoPilot
    ReactDOMClient.Root.render(
      root,
      <WrappedUtilityBar
        scenesLoaded=true isLinking=false simActive=true currentJourneyId=42 mockDispatch
      />,
    )

    await wait(50)
    let buttons3 = Dom.querySelectorAll(container, "button")
    let playBtn2 = Belt.Array.get(JsHelpers.from(buttons3), 1)->Belt.Option.getExn
    Dom.click(playBtn2)
    // When stopping, it sends multiple actions. Let's check the last one.
    // In code: dispatch(Actions.StopAutoPilot), dispatch(Actions.SetActiveScene(0, ...)), dispatch(DispatchNavigationFsmEvent(Reset))
    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.DispatchNavigationFsmEvent(Reset)))

    Dom.removeElement(container)
  })

  testAsync("should disable buttons when system is locked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let _ = OperationLifecycle.start(
      ~type_=OperationLifecycle.ProjectLoad,
      ~scope=OperationLifecycle.Blocking,
      (),
    )

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedUtilityBar
        scenesLoaded=true isLinking=false simActive=false currentJourneyId=0 mockDispatch
      />,
    )

    await wait(50)

    let buttons = Dom.querySelectorAll(container, "button")
    let plusBtn = Belt.Array.get(JsHelpers.from(buttons), 0)->Belt.Option.getExn
    let playBtn = Belt.Array.get(JsHelpers.from(buttons), 1)->Belt.Option.getExn

    let plusDisabled = Dom.getAttribute(plusBtn, "disabled")->Nullable.toOption
    let playDisabled = Dom.getAttribute(playBtn, "disabled")->Nullable.toOption

    // Check if buttons are disabled
    t->expect(plusDisabled)->Expect.toBe(Some(""))
    t->expect(playDisabled)->Expect.toBe(Some(""))

    // Try clicking - should not dispatch
    Dom.click(plusBtn)
    t->expect(lastAction.contents)->Expect.toBe(None)

    Dom.removeElement(container)
  })

  testAsync("should mark the utility rail inactive when no scenes are loaded", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockDispatch = _action => ()
    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedUtilityBar
        scenesLoaded=false isLinking=false simActive=false currentJourneyId=0 mockDispatch
      />,
    )

    await wait(50)

    let utilBar =
      Dom.querySelector(container, "#viewer-utility-bar")->Nullable.toOption->Belt.Option.getExn
    let cl = Dom.classList(utilBar)

    t->expect(Dom.ClassList.contains(cl, "is-inactive"))->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
