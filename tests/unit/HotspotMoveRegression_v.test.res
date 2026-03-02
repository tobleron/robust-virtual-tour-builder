/* tests/unit/HotspotMoveRegression_v.test.res */

open Vitest
open ReBindings
open Types

describe("Hotspot Move & Toggle Regression", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let createMockScene = (id, name): scene => {
    {
      id,
      name,
      file: Url(name),
      tinyFile: None,
      originalFile: None,
      hotspots: [
        {
          linkId: "h1",
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
          viewFrame: None,
          waypoints: None,
          displayPitch: None,
          transition: None,
          duration: None,
          isAutoForward: None,
        },
      ],
      category: "outdoor",
      floor: "ground",
      label: "",
      quality: None,
      colorGroup: None,
      _metadataSource: "user",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      sequenceId: 0,
    }
  }

  test("handleStartMovingHotspot should cancel linking mode and clear draft", t => {
    let initialState = {
      ...State.initialState,
      isLinking: true,
      linkDraft: Some({
        pitch: 1.0,
        yaw: 1.0,
        camPitch: 1.0,
        camYaw: 1.0,
        camHfov: 90.0,
        intermediatePoints: None,
        retargetHotspot: None,
        }),

    }

    let nextState = HotspotHelpers.handleStartMovingHotspot(initialState, 0, 0)

    t->expect(nextState.movingHotspot)->Expect.toEqual(Some({sceneIndex: 0, hotspotIndex: 0}))
    t->expect(nextState.isLinking)->Expect.toEqual(false)
    t->expect(nextState.linkDraft)->Expect.toEqual(None)
  })

  test("handleCommitHotspotMove should clear movingHotspot state", t => {
    let sceneId = "s1"
    let initialState = {
      ...State.initialState,
      sceneOrder: [sceneId],
      inventory: Belt.Map.String.fromArray([
        (
          sceneId,
          {
            scene: createMockScene(sceneId, "Scene1.webp"),
            status: Active,
          },
        ),
      ]),
      movingHotspot: Some({sceneIndex: 0, hotspotIndex: 0}),
    }

    let nextState = HotspotHelpers.handleCommitHotspotMove(initialState, 0, 0, 15.0, 25.0)

    t->expect(nextState.movingHotspot)->Expect.toEqual(None)

    // Verify coordinates updated in inventory
    let sceneEntry = Belt.Map.String.getExn(nextState.inventory, sceneId)
    let hs = Belt.Array.getExn(sceneEntry.scene.hotspots, 0)
    t->expect(hs.yaw)->Expect.toEqual(15.0)
    t->expect(hs.pitch)->Expect.toEqual(25.0)
  })

  testAsync(
    "PreviewArrow should have pointer-events-none and hidden sub-buttons during move",
    async t => {
      OperationLifecycle.reset()
      let container = Dom.createElement("div")
      Dom.appendChild(Dom.documentBody, container)

      let scene1 = createMockScene("s1", "Scene1.webp")
      let mockScenes = [scene1]

      // Set state to MOVING this hotspot
      let mockState = {
        ...TestUtils.createMockState(
          ~scenes=mockScenes,
          ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
          (),
        ),
        movingHotspot: Some({sceneIndex: 0, hotspotIndex: 0}),
      }

      AppContext.setBridgeState(mockState)

      let root = ReactDOMClient.createRoot(container)
      ReactDOMClient.Root.render(
        root,
        <AppContext.GlobalProvider value=mockState>
          <PreviewArrow
            sceneIndex=0
            hotspotIndex=0
            dispatch={_ => ()}
            elementId="arrow-moving"
            isTargetAutoForward=false
            scenes=mockScenes
            state=mockState
          />
        </AppContext.GlobalProvider>,
      )

      await wait(100)
      let arrow = Dom.getElementById("arrow-moving")

      switch Nullable.toOption(arrow) {
      | Some(el) =>
        // 1. Check parent pointer-events
        let className = Dom.getClassName(el)
        t->expect(String.includes(className, "pointer-events-none"))->Expect.toBe(true)

        // 2. Check inner relative wrapper has pointer-events-none
        let wrapper = Dom.querySelector(el, ".relative")
        switch Nullable.toOption(wrapper) {
        | Some(w) =>
          let wClass = Dom.getClassName(w)
          t->expect(String.includes(wClass, "pointer-events-none"))->Expect.toBe(true)

          // 3. Check that sub-buttons are NOT rendered
          // In idle mode, there are 4 children (Center, Toggle, Move, Delete)
          // In moving mode, there should only be 1 (Center) because of conditional rendering
          let childArr: array<Dom.element> = %raw(`(w) => Array.from(w.children)`)(w)
          t->expect(Belt.Array.length(childArr))->Expect.toBe(1)
        | None => t->expect("Wrapper missing")->Expect.toBe("")
        }
      | None => t->expect("Arrow missing")->Expect.toBe("")
      }

      Dom.removeElement(container)
    },
  )

  testAsync("Auto-Forward toggle should trigger immediate dispatch", async t => {
    OperationLifecycle.reset()
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scene1 = createMockScene("s1", "Scene1.webp")
    let mockScenes = [scene1]
    let mockState = TestUtils.createMockState(
      ~scenes=mockScenes,
      ~appMode=Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
      (),
    )
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    AppContext.setBridgeState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <AppContext.GlobalProvider value=mockState>
        <PreviewArrow
          sceneIndex=0
          hotspotIndex=0
          dispatch=mockDispatch
          elementId="arrow-toggle"
          isTargetAutoForward=false
          scenes=mockScenes
          state=mockState
        />
      </AppContext.GlobalProvider>,
    )

    await wait(100)
    let arrow = Dom.getElementById("arrow-toggle")
    let wrapper = Dom.querySelector(arrow->Nullable.getOrThrow, ".relative")
    let childArr: array<Dom.element> = %raw(`(w) => Array.from(w.children)`)(
      wrapper->Nullable.getOrThrow,
    )
    let toggleBtn = Belt.Array.getExn(childArr, 1)

    // Click!
    Dom.click(toggleBtn)

    // CRITICAL REGRESSION CHECK: Dispatch should happen IMMEDIATELY (no need for 800ms wait)
    t->expect(lastAction.contents != None)->Expect.toBe(true)

    Dom.removeElement(container)
  })
})
