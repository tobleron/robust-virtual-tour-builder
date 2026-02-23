open Vitest
open Types
open ReBindings

type mockFn
@send external mockClear: mockFn => unit = "mockClear"

type expectation
@val external expectCall: 'a => expectation = "expect"
@send external toHaveBeenCalledTimes: (expectation, int) => unit = "toHaveBeenCalledTimes"

%%raw(`
  let __isIdle = true;
  const __viewer = {
    getYaw: () => 0.0,
    getPitch: () => 0.0,
    setYaw: vi.fn(),
    setPitch: vi.fn(),
  };

  vi.mock('../../src/systems/Navigation/NavigationSupervisor.bs.js', () => ({
    isIdle: vi.fn(() => __isIdle),
    __setIdle: next => { __isIdle = next; },
  }));

  vi.mock('../../src/systems/ViewerSystem.bs.js', () => ({
    getActiveViewer: vi.fn(() => __viewer),
    Pool: { pool: { contents: [] }, reset: vi.fn() },
    Adapter: { destroy: vi.fn() },
    resetState: vi.fn(),
  }));

  vi.mock('../../src/components/HotspotManager.bs.js', () => ({
    syncHotspots: vi.fn(),
  }));

  vi.mock('../../src/systems/HotspotLine.bs.js', () => ({
    updateLines: vi.fn(),
  }));

  vi.mock('../../src/systems/Scene/SceneSwitcher.bs.js', () => ({
    handleAutoForward: vi.fn(),
  }));
`)

@module("../../src/systems/Navigation/NavigationSupervisor.bs.js")
external setIdle: bool => unit = "__setIdle"

@module("../../src/systems/Scene/SceneSwitcher.bs.js")
external mockHandleAutoForward: mockFn = "handleAutoForward"

let wait = ms =>
  Promise.make((resolve, _) => {
    let _ = Window.setTimeout(() => resolve(), ms)
  })

module HookHarness = {
  @react.component
  let make = (~model: state, ~dispatch: Actions.action => unit) => {
    ViewerManagerSceneLoad.useMainSceneLoading(
      ~scenes=SceneInventory.getActiveScenes(model.inventory, model.sceneOrder),
      ~activeIndex=model.activeIndex,
      ~isLinking=model.isLinking,
      ~activeYaw=model.activeYaw,
      ~activePitch=model.activePitch,
      ~getState=() => model,
      ~dispatch,
    )
    React.null
  }
}

testAsync(
  "useMainSceneLoading ignores Add Link + ESC toggles for unchanged scene (no auto-forward jump)",
  async _t => {
    let hotspot: hotspot = {
      linkId: "A16",
      yaw: -95.5,
      pitch: -15.5,
      target: "Scene B",
      targetSceneId: Some("scene-b"),
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
      isAutoForward: Some(true),
    }

    let sceneA: scene = {
      id: "scene-a",
      name: "Scene A",
      file: Url("scene-a.jpg"),
      tinyFile: None,
      originalFile: None,
      hotspots: [hotspot],
      category: "default",
      floor: "ground",
      label: "Scene A",
      quality: None,
      colorGroup: None,
      _metadataSource: "test",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      sequenceId: 0,
    }

    let modelBase = TestUtils.createMockState(
      ~scenes=[sceneA],
      ~activeIndex=0,
      (),
    )
    let modelBase = {
      ...modelBase,
      activeYaw: hotspot.yaw,
      activePitch: hotspot.pitch,
      isLinking: false,
    }

    ViewerState.state := {...ViewerState.state.contents, lastSceneId: Nullable.make(sceneA.id)}
    mockHandleAutoForward->mockClear

    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)
    let root = ReactDOMClient.createRoot(container)
    let noopDispatch: Actions.action => unit = _ => ()

    // 1) Equivalent to activating pipeline node while nav is still busy
    setIdle(false)
    ReactDOMClient.Root.render(root, <HookHarness model=modelBase dispatch=noopDispatch />)
    await wait(30)

    // 2) Add Link toggle (isLinking -> true), nav idle
    setIdle(true)
    let modelAddLink = {
      ...modelBase,
      isLinking: true,
      appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    }
    ReactDOMClient.Root.render(root, <HookHarness model=modelAddLink dispatch=noopDispatch />)
    await wait(30)

    // 3) ESC toggle (isLinking -> false), same scene and same pose
    let modelEsc = {...modelBase, isLinking: false}
    ReactDOMClient.Root.render(root, <HookHarness model=modelEsc dispatch=noopDispatch />)
    await wait(30)

    expectCall(mockHandleAutoForward)->toHaveBeenCalledTimes(0)
    Dom.removeElement(container)
  },
)
