/* tests/unit/ViewerUI_v.test.res */
open Vitest
open ReBindings
open Types

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
  viewFrame: None,
  waypoints: None,
  displayPitch: None,
  transition: None,
  duration: None,
  isAutoForward: None,
}

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

module WrappedViewerUI = {
  @react.component
  let make = (~mockState: Types.state, ~mockDispatch: Actions.action => unit) => {
    let sceneSlice: AppContext.sceneSlice = {
      scenes: SceneInventory.getActiveScenes(mockState.inventory, mockState.sceneOrder),
      activeIndex: mockState.activeIndex,
      tourName: mockState.tourName,
      activeYaw: mockState.activeYaw,
      activePitch: mockState.activePitch,
    }
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
      movingHotspot: mockState.movingHotspot,
      appMode: mockState.appMode,
      logo: mockState.logo,
      preloadingSceneIndex: mockState.preloadingSceneIndex,
    }
    let simSlice: AppContext.simSlice = {
      simulation: mockState.simulation,
      navigation: mockState.navigationState.navigation,
      currentJourneyId: mockState.navigationState.currentJourneyId,
      incomingLink: mockState.navigationState.incomingLink,
    }

    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.GlobalProvider value=mockState>
        <AppContext.SceneSliceProvider value=sceneSlice>
          <AppContext.UiSliceProvider value=uiSlice>
            <AppContext.SimSliceProvider value=simSlice>
              <ViewerUI />
            </AppContext.SimSliceProvider>
          </AppContext.UiSliceProvider>
        </AppContext.SceneSliceProvider>
      </AppContext.GlobalProvider>
    </AppContext.DispatchProvider>
  }
}

describe("ViewerUI", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  beforeEach(() => {
    OperationLifecycle.reset()
    InteractionGuard.clear()
  })

  testAsync("should render viewer UI with utility bar and static elements", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = {
      ...State.initialState,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    }
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedViewerUI mockState mockDispatch />)

    await wait(150)

    let utilBar = Dom.getElementById("viewer-utility-bar")
    t->expect(Nullable.toOption(utilBar)->Belt.Option.isSome)->Expect.toBe(true)

    let logo = Dom.getElementById("viewer-logo")
    t->expect(Nullable.toOption(logo)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should display scene label with # prefix", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = TestUtils.createMockState(
      ~scenes=[defaultScene],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedViewerUI mockState mockDispatch />)

    await wait(150)

    let labelEl = Dom.getElementById("v-scene-persistent-label")
    switch Nullable.toOption(labelEl) {
    | Some(el) =>
      t->expect(Dom.getTextContent(el))->Expect.toBe("# " ++ defaultScene.label)
      t->expect(Dom.classList(el)->Dom.ClassList.contains("state-visible"))->Expect.toBe(true)
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })

  testAsync("should show quality badges when applicable", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let quality: SharedTypes.qualityAnalysis = {
      score: 5.0,
      isBlurry: true,
      isSoft: false,
      isSeverelyDark: true,
      isSeverelyBright: false,
      isDim: false,
      hasBlackClipping: true,
      hasWhiteClipping: false,
      stats: {
        avgLuminance: 20,
        blackClipping: 15.0,
        whiteClipping: 0.0,
        sharpnessVariance: 10,
      },
      histogram: [],
      colorHist: {r: [], g: [], b: []},
      issues: 2,
      warnings: 1,
      analysis: Nullable.null,
    }

    // Use proper JSON encoding for the quality field
    let qualityJson = JsonCombinators.Json.Encode.object([
      ("score", JsonCombinators.Json.Encode.float(quality.score)),
      ("isBlurry", JsonCombinators.Json.Encode.bool(quality.isBlurry)),
      ("isSoft", JsonCombinators.Json.Encode.bool(quality.isSoft)),
      ("isSeverelyDark", JsonCombinators.Json.Encode.bool(quality.isSeverelyDark)),
      ("isSeverelyBright", JsonCombinators.Json.Encode.bool(quality.isSeverelyBright)),
      ("isDim", JsonCombinators.Json.Encode.bool(quality.isDim)),
      ("hasBlackClipping", JsonCombinators.Json.Encode.bool(quality.hasBlackClipping)),
      ("hasWhiteClipping", JsonCombinators.Json.Encode.bool(quality.hasWhiteClipping)),
      (
        "stats",
        JsonCombinators.Json.Encode.object([
          ("avgLuminance", JsonCombinators.Json.Encode.int(quality.stats.avgLuminance)),
          ("blackClipping", JsonCombinators.Json.Encode.float(quality.stats.blackClipping)),
          ("whiteClipping", JsonCombinators.Json.Encode.float(quality.stats.whiteClipping)),
          ("sharpnessVariance", JsonCombinators.Json.Encode.int(quality.stats.sharpnessVariance)),
        ]),
      ),
      (
        "histogram",
        JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.histogram),
      ),
      (
        "colorHist",
        JsonCombinators.Json.Encode.object([
          (
            "r",
            JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.colorHist.r),
          ),
          (
            "g",
            JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.colorHist.g),
          ),
          (
            "b",
            JsonCombinators.Json.Encode.array(JsonCombinators.Json.Encode.int)(quality.colorHist.b),
          ),
        ]),
      ),
      ("issues", JsonCombinators.Json.Encode.int(quality.issues)),
      ("warnings", JsonCombinators.Json.Encode.int(quality.warnings)),
      // analysis omitted
    ])

    let mockState = TestUtils.createMockState(
      ~scenes=[{...defaultScene, quality: Some(qualityJson)}],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedViewerUI mockState mockDispatch />)

    await wait(150)

    let indicator = Dom.getElementById("v-scene-quality-indicator")
    switch Nullable.toOption(indicator) {
    | Some(el) =>
      let text = Dom.getTextContent(el)
      t->expect(String.includes(text, "BLURRY"))->Expect.toBe(true)
      t->expect(String.includes(text, "DARK"))->Expect.toBe(true)
    | None => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })

  testAsync("should handle floor navigation clicks", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = TestUtils.createMockState(
      ~scenes=[defaultScene],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedViewerUI mockState mockDispatch />)

    await wait(200)

    let list = %raw(`Array.from(container.querySelectorAll('button'))`)
    let firstFloorBtn = ref(None)
    Belt.Array.forEach(
      list,
      b => {
        if %raw(`b.textContent.includes("+1")`) {
          firstFloorBtn := Some(b)
        }
      },
    )

    switch firstFloorBtn.contents {
    | Some(btn) => Dom.click(btn)
    | None => t->expect(false)->Expect.toBe(true)
    }

    switch lastAction.contents {
    | Some(Actions.UpdateSceneMetadata(0, metadata)) =>
      t->expect(Obj.magic(metadata)["floor"])->Expect.toBe("first")
    | _ => t->expect(false)->Expect.toBe(true)
    }

    Dom.removeElement(container)
  })

  testAsync("should dispatch ShowModal when hotspot menu is opened via EventBus", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let mockState = TestUtils.createMockState(
      ~scenes=[defaultScene],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedViewerUI mockState mockDispatch />)

    await wait(150)

    let anchor = Dom.createElement("div")
    let hotspot: hotspot = {
      ...defaultHotspot,
      linkId: "hs1",
      target: "s2",
      targetSceneId: None,
    }

    EventBus.dispatch(
      OpenHotspotMenu({
        "anchor": anchor,
        "hotspot": hotspot,
        "index": 0,
      }),
    )

    await wait(100)

    // Search for GO button specifically
    let goBtn = Dom.querySelector(Dom.documentBody, "button.bg-primary\\/10")
    t->expect(Nullable.toOption(goBtn)->Belt.Option.isSome)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
