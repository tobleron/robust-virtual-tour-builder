// @efficiency-role: ui-component

open ReBindings
open Types
open Actions

external idToUnknown: string => unknown = "%identity"

// Hook 5: Hotspot Sync
let useHotspotSync = (
  ~scenes: array<scene>,
  ~activeIndex: int,
  ~isLinking: bool,
  ~isTeasing: bool,
  ~getState: unit => state,
  ~dispatch: action => unit,
) => {
  React.useEffect4(() => {
    // Only run if we are NOT in linking mode (to avoid wiping the draft lines)
    if activeIndex != -1 && !isLinking && !(!NavigationSupervisor.isIdle()) {
      let v = ViewerSystem.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) =>
        if isTeasing {
          // Nuke hotspots during teaser to prevent interactions
          let config = Viewer.getConfig(viewer)
          let hs = config["hotSpots"]
          let currentIds = Belt.Array.map(hs, h => h["id"])
          Belt.Array.forEach(currentIds, id => {
            if id != "" {
              Viewer.removeHotSpot(viewer, id)
            }
          })
          HotspotLine.updateLines(viewer, getState(), ())
        } else {
          switch Belt.Array.get(scenes, activeIndex) {
          | Some(scene) =>
            // Robustness: Only sync if the viewer actually belongs to this scene
            let viewerSceneId = ViewerSystem.Adapter.getMetaData(viewer, "sceneId")
            let targetId = idToUnknown(scene.id)
            let currentState = getState()

            if viewerSceneId == Some(targetId) {
              Logger.debug(
                ~module_="ViewerManagerHotspots",
                ~message="SYNC_HOTSPOTS",
                ~data=Some({"sceneId": scene.id}),
                (),
              )
              HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
              HotspotLine.updateLines(viewer, currentState, ())
            }
          | None => ()
          }
        }
      | None => ()
      }
    }
    None
  }, (scenes, isLinking, isTeasing, activeIndex))
}

// Hook 9: Hotspot Line Render Loop
let useHotspotLineLoop = (~getState: unit => state, dispatch: action => unit) => {
  React.useEffect0(() => {
    let animationFrameId = ref(None)
    let lastPitch = ref(-999.0)
    let lastYaw = ref(-999.0)
    let lastHfov = ref(-999.0)

    // Handle Forced Sync from EventBus (breaks dependencies)
    let unsub = EventBus.subscribe(e => {
      switch e {
      | ForceHotspotSync =>
        let _ = Window.requestAnimationFrame(
          _ => {
            let v = ViewerSystem.getActiveViewer()
            let currentState = getState()
            let activeScenes = SceneInventory.getActiveScenes(
              currentState.inventory,
              currentState.sceneOrder,
            )
            switch (Nullable.toOption(v), Belt.Array.get(activeScenes, currentState.activeIndex)) {
            | (Some(viewer), Some(scene)) =>
              // During forced sync, we allow it even if Stabilizing as long as it's not Loading/Swapping
              let status = NavigationSupervisor.getStatus()
              let isBusy = switch status {
              | Loading(_) | Swapping(_) => true
              | _ => false
              }

              if !isBusy && ViewerSystem.isViewerReady(viewer) {
                try {
                  if !currentState.isTeasing {
                    HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
                  } else {
                    // Force clear if we somehow got here during teaser
                    let config = Viewer.getConfig(viewer)
                    let hs = config["hotSpots"]
                    let currentIds = Belt.Array.map(hs, h => h["id"])
                    Belt.Array.forEach(
                      currentIds,
                      id => {
                        if id != "" {
                          Viewer.removeHotSpot(viewer, id)
                        }
                      },
                    )
                  }
                } catch {
                | e =>
                  let (msg, _) = Logger.getErrorDetails(e)
                  Logger.warn(
                    ~module_="ViewerManagerHotspots",
                    ~message="FORCE_SYNC_FAILED",
                    ~data=Some({"error": msg}),
                    (),
                  )
                }
              } else {
                HotspotLine.clearLines()
              }
            | _ => ()
            }
          },
        )
      | PreviewLinkId(linkId) =>
        let currentState = getState()
        let activeScenes = SceneInventory.getActiveScenes(
          currentState.inventory,
          currentState.sceneOrder,
        )
        let fromActiveScene = switch Belt.Array.get(activeScenes, currentState.activeIndex) {
        | Some(currentScene) =>
          Belt.Array.getIndexBy(currentScene.hotspots, h => h.linkId == linkId)
          ->Option.flatMap(hIdx =>
            Belt.Array.get(currentScene.hotspots, hIdx)
            ->Option.map(hotspot => (currentState.activeIndex, hIdx, hotspot))
          )
        | None => None
        }

        let fallbackSearch =
          if fromActiveScene->Option.isSome {
            None
          } else {
            activeScenes
            ->Belt.Array.mapWithIndex((sceneIdx, scene) =>
              Belt.Array.getIndexBy(scene.hotspots, h => h.linkId == linkId)->Option.flatMap(hIdx =>
                Belt.Array.get(scene.hotspots, hIdx)->Option.map(hotspot => (sceneIdx, hIdx, hotspot))
              )
            )
            ->Belt.Array.keepMap(x => x)
            ->Belt.Array.get(0)
          }

        let resolvedSource = switch fromActiveScene {
        | Some(_) as found => found
        | None => fallbackSearch
        }

        switch resolvedSource {
        | Some((fromSceneIdx, hIdx, hotspot)) =>
          switch HotspotTarget.resolveSceneIndex(activeScenes, hotspot) {
          | Some(tIdx) =>
            let (ny, np, nh) = PreviewArrow.Logic.calculateNavParams(hotspot)
            Scene.Switcher.navigateToScene(
              dispatch,
              currentState,
              tIdx,
              fromSceneIdx,
              hIdx,
              ~targetYaw=ny,
              ~targetPitch=np,
              ~targetHfov=nh,
              ~previewOnly=true,
              (),
            )
          | None => ()
          }
        | None =>
          Logger.warn(
            ~module_="ViewerManagerHotspots",
            ~message="PREVIEW_LINK_NOT_FOUND",
            ~data=Some({"linkId": linkId, "activeIndex": currentState.activeIndex}),
            (),
          )
        }
      | _ => ()
      }
    })

    let rec loop = () => {
      let v = ViewerSystem.getActiveViewer()
      switch Nullable.toOption(v) {
      | Some(viewer) =>
        let currentState = getState()

        // CRITICAL: Skip updates during viewer swap to prevent race condition

        let status = NavigationSupervisor.getStatus()
        let isCriticalBusy = switch status {
        | Loading(_) | Swapping(_) => true
        | _ => false
        }

        if !isCriticalBusy && ViewerSystem.isViewerReady(viewer) {
          let p = Viewer.getPitch(viewer)
          let y = Viewer.getYaw(viewer)
          let h = Viewer.getHfov(viewer)

          lastPitch := p
          lastYaw := y
          lastHfov := h
          try {
            HotspotLine.updateLines(viewer, currentState, ())
          } catch {
          | _ => () // Transient error during viewer swap/init is expected
          }
        } else {
          HotspotLine.clearLines()
        }
      | None => ()
      }
      animationFrameId := Some(Window.requestAnimationFrame(loop))
    }

    // Start loop
    animationFrameId := Some(Window.requestAnimationFrame(loop))

    Some(
      () => {
        unsub()
        switch animationFrameId.contents {
        | Some(id) => Window.cancelAnimationFrame(id)
        | None => ()
        }
      },
    )
  })
}
