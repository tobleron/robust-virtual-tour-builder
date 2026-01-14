/* src/components/ViewerManager.res */

open ReBindings
open ViewerTypes
open ViewerState
open ViewerLoader

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
          Notification.notify("Link Cancelled", "info")
        }
      }
    }

    Window.addEventListener("keydown", handleKeyDown)

    Some(
      () => {
        Window.removeEventListener("keydown", handleKeyDown)
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

  React.null
}
