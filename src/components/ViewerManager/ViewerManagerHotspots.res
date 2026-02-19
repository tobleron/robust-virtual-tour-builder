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
  ~getState: unit => state,
  ~dispatch: action => unit,
) => {
  React.useEffect3(() => {
    // Only run if we are NOT in linking mode (to avoid wiping the draft lines)
    if activeIndex != -1 && !isLinking && !(!NavigationSupervisor.isIdle()) {
      switch Belt.Array.get(scenes, activeIndex) {
      | Some(scene) =>
        let v = ViewerSystem.getActiveViewer()
        switch Nullable.toOption(v) {
        | Some(viewer) =>
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
      | None => ()
      }
    }
    None
  }, (scenes, isLinking, activeIndex))
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
            switch (
              Nullable.toOption(v),
              Belt.Array.get(currentState.scenes, currentState.activeIndex),
            ) {
            | (Some(viewer), Some(scene)) =>
              // During forced sync, we allow it even if Stabilizing as long as it's not Loading/Swapping
              let status = NavigationSupervisor.getStatus()
              let isBusy = switch status {
              | Loading(_) | Swapping(_) => true
              | _ => false
              }

              if !isBusy {
                try {
                  HotspotManager.syncHotspots(viewer, currentState, scene, dispatch)
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
              }
            | _ => ()
            }
          },
        )
      | PreviewLinkId(linkId) =>
        let currentState = getState()
        switch Belt.Array.get(currentState.scenes, currentState.activeIndex) {
        | Some(currentScene) =>
          switch Belt.Array.getIndexBy(currentScene.hotspots, h => h.linkId == linkId) {
          | Some(hIdx) =>
            switch currentScene.hotspots[hIdx] {
            | Some(hotspot) =>
              switch HotspotTarget.resolveSceneIndex(currentState.scenes, hotspot) {
              | Some(tIdx) =>
                let (ny, np, nh) = PreviewArrow.Logic.calculateNavParams(hotspot)
                Scene.Switcher.navigateToScene(
                  dispatch,
                  currentState,
                  tIdx,
                  currentState.activeIndex,
                  hIdx,
                  ~targetYaw=ny,
                  ~targetPitch=np,
                  ~targetHfov=nh,
                  ~previewOnly=true,
                  (),
                )
              | None => ()
              }
            | None => ()
            }
          | None => ()
          }
        | None => ()
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

        if !isCriticalBusy {
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
