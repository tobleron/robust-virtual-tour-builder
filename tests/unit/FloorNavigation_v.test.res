// @efficiency: infra-adapter
open Vitest
open ReBindings
open Types

module WrappedFloorNavigation = {
  @react.component
  let make = (~scenesLoaded, ~activeIndex, ~isLinking, ~scenes, ~mockDispatch) => {
    let sceneSlice: AppContext.sceneSlice = {
      scenes,
      activeIndex,
      tourName: "Test Tour",
      activeYaw: 0.0,
      activePitch: 0.0,
    }
    let uiSlice: AppContext.uiSlice = {
      isLinking,
      isTeasing: false,
      linkDraft: None,
      movingHotspot: None,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      logo: None,
      preloadingSceneIndex: -1,
    }
    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.SceneSliceProvider value=sceneSlice>
        <AppContext.UiSliceProvider value=uiSlice>
          <FloorNavigation scenesLoaded activeIndex isLinking />
        </AppContext.UiSliceProvider>
      </AppContext.SceneSliceProvider>
    </AppContext.DispatchProvider>
  }
}

describe("FloorNavigation", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  beforeEach(() => {
    OperationLifecycle.reset()
    InteractionGuard.clear()
  })

  let defaultScene: scene = {
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

  testAsync("should handle floor button clicks", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scenes = [{...defaultScene, floor: "ground"}]
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <WrappedFloorNavigation
        scenesLoaded=true activeIndex=0 isLinking=false scenes mockDispatch
      />,
    )

    await wait(200)

    let buttons = Dom.querySelectorAll(container, "button")
    let buttonsArr = JsHelpers.from(buttons)

    // Find the "+1" button for first floor
    let firstFloorBtn = ref(None)
    Belt.Array.forEach(
      buttonsArr,
      b => {
        if String.includes(Dom.getTextContent(b), "+1") {
          firstFloorBtn := Some(b)
        }
      },
    )

    switch firstFloorBtn.contents {
    | Some(btn) => Dom.click(btn)
    | None => ()
    }

    switch lastAction.contents {
    | Some(Actions.UpdateSceneMetadata(0, metadata)) =>
      t->expect(Obj.magic(metadata)["floor"])->Expect.toBe("first")
    | _ => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })
})
