// @efficiency: infra-adapter
open Vitest
open ReBindings

module WrappedUtilityBar = {
  @react.component
  let make = (~scenesLoaded, ~isLinking, ~simActive, ~currentJourneyId, ~mockDispatch) => {
    <AppContext.DispatchProvider value=mockDispatch>
      <UtilityBar scenesLoaded isLinking simActive currentJourneyId />
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

    let v = Nullable.toOption(ReBindings.Viewer.instance)
    let viewer = Belt.Option.getExn(v)
    let currentYaw = ReBindings.Viewer.getYaw(viewer)
    let currentPitch = ReBindings.Viewer.getPitch(viewer)
    let currentHfov = ReBindings.Viewer.getHfov(viewer)

    let expectedDraft: Types.linkDraft = {
      yaw: currentYaw,
      pitch: currentPitch,
      camYaw: currentYaw,
      camPitch: currentPitch,
      camHfov: currentHfov,
      intermediatePoints: None,
    }

    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.StartLinking(Some(expectedDraft))))

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

    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.StartAutoPilot(42, false)))

    // Now test StopAutoPilot
    ReactDOMClient.Root.render(
      root,
      <WrappedUtilityBar
        scenesLoaded=true isLinking=false simActive=true currentJourneyId=42 mockDispatch
      />,
    )

    await wait(50)
    Dom.click(playBtn)
    // When stopping, it sends multiple actions. Let's check the last one.
    // In code: dispatch(Actions.StopAutoPilot), dispatch(Actions.SetActiveScene(0, ...)), dispatch(DispatchNavigationFsmEvent(Reset))
    t->expect(lastAction.contents)->Expect.toEqual(Some(Actions.DispatchNavigationFsmEvent(Reset)))

    Dom.removeElement(container)
  })
})
