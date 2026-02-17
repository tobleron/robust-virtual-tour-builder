open Vitest
open ReBindings
open Types

describe("PreviewArrow", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  let createMockScene = (id, name, targetName, isAutoForward): scene => {
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
          target: targetName,
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
      isAutoForward,
    }
  }

  testAsync("should render arrow and handle interactions", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scene1 = createMockScene("s1", "Scene1.webp", "Scene2.webp", false)
    let scene2 = createMockScene("s2", "Scene2.webp", "Scene3.webp", false)

    let mockScenes = [scene1, scene2]

    let mockState = {
      ...State.initialState,
      scenes: mockScenes,
      activeIndex: 0,
    }

    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    AppContext.setBridgeState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <PreviewArrow
        sceneIndex=0
        hotspotIndex=0
        dispatch=mockDispatch
        elementId="arrow-1"
        isTargetAutoForward=false
        scenes=mockScenes
        state=mockState
      />,
    )

    await wait(100)

    let arrow = Dom.getElementById("arrow-1")
    t->expect(Belt.Option.isSome(Nullable.toOption(arrow)))->Expect.toBe(true)

    // Test Right Click (Toggle AutoForward)
    // We simulate a click on the right button (the second child of the inner flex container)
    // Structure: div#id > div.relative > div(Center), div(Right), div(Bottom)
    let rightBtn = switch Nullable.toOption(arrow) {
    | Some(el) =>
      let wrapper = Dom.querySelector(el, ".relative")
      switch Nullable.toOption(wrapper) {
      | Some(w) =>
        // Use children instead of querySelectorAll to get immediate children
        let childArr: array<Dom.element> = %raw(`(w) => Array.from(w.children)`)(w)
        if Belt.Array.length(childArr) >= 2 {
          Some(Belt.Array.getExn(childArr, 1))
        } else {
          None
        }
      | None => None
      }
    | None => None
    }

    // Subscribe to NotificationManager to check notification
    let notificationReceived = ref(false)
    let unsub = NotificationManager.subscribe(
      queueState => {
        Belt.Array.forEach(
          queueState.pending,
          notif => {
            if String.includes(notif.message, "Auto-Forward Enabled") {
              notificationReceived := true
            }
          },
        )
        Belt.Array.forEach(
          queueState.active,
          notif => {
            if String.includes(notif.message, "Auto-Forward Enabled") {
              notificationReceived := true
            }
          },
        )
      },
    )

    switch rightBtn {
    | Some(btn) =>
      Dom.click(btn)
      // Wait for yellow flicker timeout (800ms)
      await wait(1000)

      // Check action
      switch lastAction.contents {
      | Some(UpdateSceneMetadata(idx, _json)) => t->expect(idx)->Expect.toBe(1) // Target scene index
      | _ => t->expect(lastAction.contents != None)->Expect.toBe(true)
      }

    | None => t->expect("Right button not found")->Expect.toBe("")
    }

    unsub()
    Dom.removeElement(container)
  })

  testAsync("should handle delete click", async t => {
    let container = Dom.createElement("div")
    Dom.appendChild(Dom.documentBody, container)

    let scene1 = createMockScene("s1", "Scene1.webp", "Scene2.webp", false)
    let mockScenes = [scene1]
    let mockState = {...State.initialState, scenes: mockScenes}
    let lastAction = ref(None)
    let mockDispatch = action => lastAction := Some(action)

    AppContext.setBridgeState(mockState)

    let root = ReactDOMClient.createRoot(container)
    ReactDOMClient.Root.render(
      root,
      <PreviewArrow
        sceneIndex=0
        hotspotIndex=0
        dispatch=mockDispatch
        elementId="arrow-delete"
        isTargetAutoForward=false
        scenes=mockScenes
        state=mockState
      />,
    )

    await wait(100)
    let arrow = Dom.getElementById("arrow-delete")

    // 3rd div is delete button
    let deleteBtn = switch Nullable.toOption(arrow) {
    | Some(el) =>
      let wrapper = Dom.querySelector(el, ".relative")
      switch Nullable.toOption(wrapper) {
      | Some(w) =>
        let childArr: array<Dom.element> = %raw(`(w) => Array.from(w.children)`)(w)
        if Belt.Array.length(childArr) >= 3 {
          Some(Belt.Array.getExn(childArr, 2))
        } else {
          None
        }
      | None => None
      }
    | None => None
    }

    switch deleteBtn {
    | Some(btn) =>
      Dom.click(btn)
      // Wait for red flicker timeout (800ms)
      await wait(1000)

      switch lastAction.contents {
      | Some(RemoveHotspot(sIdx, hIdx)) =>
        t->expect(sIdx)->Expect.toBe(0)
        t->expect(hIdx)->Expect.toBe(0)
      | _ => t->expect("RemoveHotspot action missing")->Expect.toBe("")
      }
    | None => t->expect("Delete button not found")->Expect.toBe("")
    }

    Dom.removeElement(container)
  })
})
