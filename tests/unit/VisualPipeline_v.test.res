// @efficiency: infra-adapter
/* tests/unit/VisualPipeline_v.test.res */
open Vitest
open ReBindings
open Types

module WrappedVisualPipeline = {
  @react.component
  let make = (~mockState: Types.state, ~mockDispatch: Actions.action => unit) => {
    let activeScenes = SceneInventory.getActiveScenes(mockState.inventory, mockState.sceneOrder)
    let sceneSlice: AppContext.sceneSlice = {
      scenes: activeScenes,
      activeIndex: mockState.activeIndex,
      tourName: mockState.tourName,
      activeYaw: mockState.activeYaw,
      activePitch: mockState.activePitch,
    }
    let uiSlice: AppContext.uiSlice = {
      isLinking: mockState.isLinking,
      isTeasing: mockState.isTeasing,
      linkDraft: mockState.linkDraft,
      appMode: mockState.appMode,
      logo: mockState.logo,
      preloadingSceneIndex: mockState.preloadingSceneIndex,
    }
    let pipelineSlice: AppContext.pipelineSlice = {
      scenes: activeScenes,
      activeIndex: mockState.activeIndex,
      timeline: mockState.timeline,
      activeTimelineStepId: mockState.activeTimelineStepId,
    }

    <AppContext.DispatchProvider value=mockDispatch>
      <AppContext.GlobalProvider value=mockState>
        <AppContext.SceneSliceProvider value=sceneSlice>
          <AppContext.UiSliceProvider value=uiSlice>
            <AppContext.PipelineSliceProvider value=pipelineSlice>
              <VisualPipeline />
            </AppContext.PipelineSliceProvider>
          </AppContext.UiSliceProvider>
        </AppContext.SceneSliceProvider>
      </AppContext.GlobalProvider>
    </AppContext.DispatchProvider>
  }
}

describe("VisualPipeline", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  afterEach(() => {
    OperationLifecycle.reset()
    InteractionGuard.clear()
  })

  testAsync("should render pipeline items", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scene: Types.scene = {
      id: "s1",
      name: "Scene 1",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [
        {
          linkId: "h1",
          yaw: 0.0,
          pitch: 0.0,
          target: "s1",
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
          isAutoForward: None,
        },
      ],
      category: "",
      floor: "1",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
    }

    let mockState = TestUtils.createMockState(
      ~scenes=[scene],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockState = {...mockState, timeline: [
        {
          id: "t1",
          sceneId: "s1",
          linkId: "h1",
          targetScene: "s1",
          transition: "cut",
          duration: 0,
        },
      ]}
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedVisualPipeline mockState mockDispatch />)

    await wait(100)

    let nodes = Dom.querySelectorAll(container, ".pipeline-node")
    t->expect(Dom.nodeListLength(nodes) > 0)->Expect.toBe(true)

    Dom.removeElement(container)
  })

  testAsync("should not show hover preview when system is locked", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scene: Types.scene = {
      id: "s1",
      name: "Scene 1",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "",
      floor: "1",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
    }

    let _ = OperationLifecycle.start(
      ~type_=OperationLifecycle.ProjectLoad,
      ~scope=OperationLifecycle.Blocking,
      (),
    )

    let mockState = TestUtils.createMockState(
      ~scenes=[scene],
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedVisualPipeline mockState mockDispatch />)

    await wait(100)

    // Trigger hover
    let node = Dom.querySelector(container, ".pipeline-node")
    switch Nullable.toOption(node) {
    | Some(el) =>
      %raw(`(el) => el.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }))`)(el)
    | None => ()
    }

    await wait(50)

    let tooltip = Dom.querySelector(container, ".pipeline-global-tooltip")
    t->expect(Nullable.toOption(tooltip))->Expect.toBe(None)

    Dom.removeElement(container)
  })
})
