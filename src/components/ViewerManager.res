/* src/components/ViewerManager.res */

open ReBindings
open ViewerTypes
open ViewerState
open ViewerLoader
open EventBus

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  // Initialization (once)
  React.useEffect0(() => {
    NavigationRenderer.init() // Legacy init for now

    let handleKeyDown = e => {
      let key = Obj.magic(e)["key"]
      if key == "Escape" {
        if state.isLinking {
          dispatch(Actions.SetIsLinking(false))
          dispatch(Actions.SetLinkDraft(None))
          EventBus.dispatch(ShowNotification("Link Cancelled", #Info))
        }
      }
    }

    Window.addEventListener("keydown", handleKeyDown)

    // Initialize Guide
    ViewerState.state.guide = Dom.getElementById("cursor-guide")

    // Mouse Move listener for Stage (to track lastMouseEvent and update cursor logic)
    let handleMouseMove = e => {
      ViewerState.state.lastMouseEvent = Nullable.make(e)

      let stage = Dom.getElementById("viewer-stage")
      switch Nullable.toOption(stage) {
      | Some(el) =>
        let rect = Dom.getBoundingClientRect(el)
        let clientX = Belt.Int.toFloat(Obj.magic(e)["clientX"])
        let clientY = Belt.Int.toFloat(Obj.magic(e)["clientY"])

        let x = clientX -. rect.left
        let y = clientY -. rect.top

        ViewerState.state.mouseXNorm = x /. rect.width *. 2.0 -. 1.0
        ViewerState.state.mouseYNorm = y /. rect.height *. 2.0 -. 1.0

        // Update Rod Position
        let guide = Dom.getElementById("cursor-guide")
        switch Nullable.toOption(guide) {
        | Some(g) =>
          if state.isLinking {
            Dom.setDisplay(g, "block")
            Dom.setLeft(g, Float.toString(Math.round(clientX)) ++ "px")
            Dom.setTop(g, Float.toString(Math.round(clientY)) ++ "px")
            Dom.setStyleHeight(g, Float.toString(Math.round(rect.height -. y)) ++ "px")
          } else {
            Dom.setDisplay(g, "none")
          }
        | None => ()
        }
      | None => ()
      }
    }

    let stage = Dom.getElementById("viewer-stage")
    switch Nullable.toOption(stage) {
    | Some(el) => Dom.addEventListener(el, "mousemove", handleMouseMove)
    | None => ()
    }

    Some(
      () => {
        Window.removeEventListener("keydown", handleKeyDown)
        // Ensure guide is hidden on unmount/cleanup
        let guide = Dom.getElementById("cursor-guide")
        switch Nullable.toOption(guide) {
        | Some(g) => Dom.setDisplay(g, "none")
        | None => ()
        }

        switch Nullable.toOption(stage) {
        | Some(el) => Dom.removeEventListener(el, "mousemove", handleMouseMove)
        | None => ()
        }
      },
    )
  })

  // State Sync
  React.useEffect1(() => {
    if Belt.Array.length(state.scenes) == 0 {
      /* Cleanup logic */
      let vA = ViewerState.state.viewerA
      let vB = ViewerState.state.viewerB

      switch Nullable.toOption(vA) {
      | Some(v) =>
        try {Viewer.destroy(v)} catch {
        | _ => ()
        }
      | None => ()
      }
      switch Nullable.toOption(vB) {
      | Some(v) =>
        try {Viewer.destroy(v)} catch {
        | _ => ()
        }
      | None => ()
      }

      ViewerState.state.viewerA = Nullable.null
      ViewerState.state.viewerB = Nullable.null
      ViewerState.state.activeViewerKey = A
      ViewerState.resetState()

      let pA = Dom.getElementById("panorama-a")
      let pB = Dom.getElementById("panorama-b")
      switch Nullable.toOption(pA) {
      | Some(el) => Dom.add(el, "active")
      | None => ()
      }
      switch Nullable.toOption(pB) {
      | Some(el) => Dom.remove(el, "active")
      | None => ()
      }
    } else {
      /* Check Link Follow Loop */
      // ViewerFollow needs to be refactored too, but for now...
      if state.isLinking && !ViewerState.state.followLoopActive {
        ViewerState.state.followLoopActive = true
        ViewerFollow.updateFollowLoop()
      }

      /* Load Scene */
      let preIndex = state.preloadingSceneIndex
      let isPre =
        preIndex != -1 &&
        preIndex != ViewerState.state.lastPreloadingIndex &&
        preIndex != state.activeIndex

      if isPre {
        ViewerState.state.lastPreloadingIndex = preIndex
        Loader.loadNewScene(Nullable.toOption(ViewerState.state.lastSceneId), Some(preIndex))
      }

      let currentScene = Belt.Array.get(state.scenes, state.activeIndex)
      switch currentScene {
      | Some(sc) =>
        let hasSceneChanged = Nullable.toOption(ViewerState.state.lastSceneId) != Some(sc.id)
        if hasSceneChanged {
          let prev = Nullable.toOption(ViewerState.state.lastSceneId)
          Loader.loadNewScene(prev, None)
        } else {
          /* Same scene, sync Hotsopts and View */
          let v = getActiveViewer()
          switch Nullable.toOption(v) {
          | Some(viewer) =>
            /* Sync Hotspots */
            HotspotManager.syncHotspots(viewer, state, sc, dispatch)

            /* Sync View if needed */
            if state.activeYaw != 0.0 || state.activePitch != 0.0 {
              // Logic for matching ...
              ()
            }
          | None => ()
          }
          /* Trigger AutoForward if applicable */
          Navigation.handleAutoForward(dispatch, state, sc)
        }
      | None => ()
      }
    }
    None
  }, [state])

  // Arrival tracking for Simulation
  React.useEffect2(() => {
    if state.activeIndex != -1 && state.isSimulationMode {
      SimulationSystem.onSceneArrival(state.activeIndex, true)
    }
    None
  }, (state.activeIndex, state.isSimulationMode))

  // Sync Linking Cursor
  React.useEffect1(() => {
    let body = Dom.documentBody
    if state.isLinking {
      Dom.classList(body)->Dom.ClassList.add("linking-mode")
    } else {
      Dom.classList(body)->Dom.ClassList.remove("linking-mode")
    }
    None
  }, [state.isLinking])

  React.null
}
