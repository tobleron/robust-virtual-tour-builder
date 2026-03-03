// @efficiency: infra-adapter
// @vitest-environment jsdom
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
      discoveringTitleCount: mockState.discoveringTitleCount,
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

let getSupervisorTarget = () =>
  NavigationSupervisor.getCurrentTask()->Option.map(task => task.targetSceneId)

let makeSelfHotspot = (sceneId: string): Types.hotspot => {
  linkId: "self_" ++ sceneId,
  yaw: 0.0,
  pitch: 0.0,
  target: "",
  targetSceneId: Some(sceneId),
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

describe("VisualPipeline", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  beforeEach(() => {
    switch NavigationSupervisor.getCurrentTask() {
    | Some(task) => NavigationSupervisor.abort(task.token.id)
    | None => ()
    }
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
          viewFrame: None,
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
      sequenceId: 0,
    }

    let mockState = TestUtils.createMockState(
      ~scenes=[scene],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockState = {
      ...mockState,
      timeline: [
        {
          id: "t1",
          sceneId: "s1",
          linkId: "h1",
          targetScene: "s1",
          transition: "cut",
          duration: 0,
        },
      ],
    }
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
      hotspots: [makeSelfHotspot("s1")],
      category: "",
      floor: "1",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 0,
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
    let node = %raw(`root => root.querySelectorAll('.pipeline-node')[1] ?? null`)(container)
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

  testAsync("clicking a pipeline node should switch to target scene", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let sourceScene: Types.scene = {
      id: "s1",
      name: "Scene 1",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [
        {
          linkId: "h1",
          yaw: 15.0,
          pitch: 5.0,
          target: "Scene 2",
          targetSceneId: Some("s2"),
          targetYaw: Some(45.0),
          targetPitch: Some(-5.0),
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
      sequenceId: 0,
    }

    let targetScene: Types.scene = {
      id: "s2",
      name: "Scene 2",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [makeSelfHotspot("s2")],
      category: "",
      floor: "2",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 1,
    }

    let mockState = TestUtils.createMockState(
      ~scenes=[sourceScene, targetScene],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockState = {
      ...mockState,
      timeline: [
        {
          id: "step-1",
          sceneId: "s1",
          linkId: "h1",
          targetScene: "s2",
          transition: "fade",
          duration: 1000,
        },
      ],
    }

    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedVisualPipeline mockState mockDispatch />)
    await wait(100)

    let node = %raw(`root => root.querySelectorAll('.pipeline-node')[1] ?? null`)(container)
    switch Nullable.toOption(node) {
    | Some(el) => %raw(`(el) => el.dispatchEvent(new MouseEvent('click', { bubbles: true }))`)(el)
    | None => ()
    }

    await wait(40)

    t->expect(getSupervisorTarget())->Expect.toEqual(Some("s2"))
    Dom.removeElement(container)
  })

  testAsync(
    "clicking a pipeline node should fall back to source scene when target is missing",
    async t => {
      let container = Dom.createElement("div")
      Dom.appendChild(Dom.documentBody, container)

      let sourceScene: Types.scene = {
        id: "s1",
        name: "Scene 1",
        label: "",
        file: Url(""),
        tinyFile: None,
        originalFile: None,
        hotspots: [
          {
            linkId: "h1",
            yaw: 12.0,
            pitch: -3.0,
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
        sequenceId: 0,
      }

      let otherScene: Types.scene = {
        id: "s2",
        name: "Scene 2",
        label: "",
        file: Url(""),
        tinyFile: None,
        originalFile: None,
        hotspots: [makeSelfHotspot("s2")],
        category: "",
        floor: "2",
        quality: None,
        colorGroup: None,
        categorySet: false,
        labelSet: false,
        _metadataSource: "user",
        isAutoForward: false,
        sequenceId: 1,
      }

      let mockState = TestUtils.createMockState(
        ~scenes=[sourceScene, otherScene],
        ~activeIndex=0,
        ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
        (),
      )
      let mockState = {
        ...mockState,
        timeline: [
          {
            id: "step-2",
            sceneId: "s1",
            linkId: "h1",
            targetScene: "",
            transition: "fade",
            duration: 1000,
          },
        ],
      }

      let mockDispatch = _ => ()

      let root = ReactDOMClient.createRoot(container)
      ReactDOMClient.Root.render(root, <WrappedVisualPipeline mockState mockDispatch />)
      await wait(100)

      let node = Dom.querySelector(container, ".pipeline-node")
      switch Nullable.toOption(node) {
      | Some(el) => %raw(`(el) => el.dispatchEvent(new MouseEvent('click', { bubbles: true }))`)(el)
      | None => ()
      }

      await wait(40)

      t->expect(getSupervisorTarget())->Expect.toEqual(Some("s1"))
      Dom.removeElement(container)
    },
  )

  testAsync("locked pipeline should ignore click activation", async t => {
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
          targetSceneId: Some("s1"),
          targetYaw: Some(0.0),
          targetPitch: Some(0.0),
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
      sequenceId: 0,
    }

    let _ = OperationLifecycle.start(
      ~type_=OperationLifecycle.ProjectLoad,
      ~scope=OperationLifecycle.Blocking,
      (),
    )

    let mockState = TestUtils.createMockState(
      ~scenes=[scene],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockState = {
      ...mockState,
      timeline: [
        {
          id: "step-3",
          sceneId: "s1",
          linkId: "h1",
          targetScene: "s1",
          transition: "fade",
          duration: 1000,
        },
      ],
    }

    let mockDispatch = _ => ()

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedVisualPipeline mockState mockDispatch />)
    await wait(100)

    let node = Dom.querySelector(container, ".pipeline-node")
    switch Nullable.toOption(node) {
    | Some(el) => %raw(`(el) => el.dispatchEvent(new MouseEvent('click', { bubbles: true }))`)(el)
    | None => ()
    }

    await wait(40)

    t->expect(getSupervisorTarget())->Expect.toEqual(None)
    Dom.removeElement(container)
  })

  testAsync("renders traversal connectors without numeric hub badges", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let hubScene: Types.scene = {
      id: "s1",
      name: "Entrance",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [
        {
          linkId: "h1",
          yaw: 10.0,
          pitch: 0.0,
          target: "s2",
          targetSceneId: Some("s2"),
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
        },
        {
          linkId: "h2",
          yaw: -10.0,
          pitch: 0.0,
          target: "s3",
          targetSceneId: Some("s3"),
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
        },
      ],
      category: "",
      floor: "ground",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 0,
    }

    let s2: Types.scene = {
      id: "s2",
      name: "Corridor",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [makeSelfHotspot("s2")],
      category: "",
      floor: "ground",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 1,
    }

    let s3: Types.scene = {
      id: "s3",
      name: "Living",
      label: "",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [makeSelfHotspot("s3")],
      category: "",
      floor: "ground",
      quality: None,
      colorGroup: None,
      categorySet: false,
      labelSet: false,
      _metadataSource: "user",
      isAutoForward: false,
      sequenceId: 2,
    }

    let mockState = TestUtils.createMockState(
      ~scenes=[hubScene, s2, s3],
      ~activeIndex=0,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let mockState = {
      ...mockState,
      timeline: [
        {
          id: "step-1",
          sceneId: "s1",
          linkId: "h1",
          targetScene: "s2",
          transition: "fade",
          duration: 1000,
        },
        {
          id: "step-2",
          sceneId: "s1",
          linkId: "h2",
          targetScene: "s3",
          transition: "fade",
          duration: 1000,
        },
      ],
    }

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(root, <WrappedVisualPipeline mockState mockDispatch={_ => ()} />)
    await wait(120)

    let edgeLines = Dom.querySelectorAll(container, ".pipeline-edge-line")
    let hubBadges = Dom.querySelectorAll(container, ".pipeline-hub-badge")
    t->expect(Dom.nodeListLength(edgeLines) > 0)->Expect.toBe(true)
    t->expect(Dom.nodeListLength(hubBadges))->Expect.toBe(0)

    Dom.removeElement(container)
  })
})
