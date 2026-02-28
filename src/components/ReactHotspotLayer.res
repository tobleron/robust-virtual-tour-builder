/* src/components/ReactHotspotLayer.res */
open ReBindings
open Types

external makeStyle: {..} => ReactDOM.Style.t = "%identity"
let sceneIdFromMeta: option<unknown> => string = %raw("(meta) => typeof meta === 'string' ? meta : ''")

@react.component
let make = React.memo(() => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let uiSlice = AppContext.useUiSlice()
  let isTeasing = uiSlice.isTeasing

  let (cam, setCam) = React.useState(_ => None)
  let (containerRect, setContainerRect) = React.useState(_ => None)
  let (viewerSceneId, setViewerSceneId) = React.useState(_ => "")

  // Position update loop
  React.useEffect0(() => {
    let animationFrameId = ref(None)

    let rec loop = () => {
      let v = ViewerSystem.getActiveViewer()
      let svgOpt = Dom.getElementById("viewer-hotspot-lines")

      switch (Nullable.toOption(v), Nullable.toOption(svgOpt)) {
      | (Some(viewer), Some(svg)) =>
        let status = NavigationSupervisor.getStatus()
        let isCriticalBusy = switch status {
        | Loading(_) | Swapping(_) => true
        | _ => false
        }

        if isCriticalBusy || !ViewerSystem.isViewerReady(viewer) {
          setCam(_ => None)
          setContainerRect(_ => None)
          setViewerSceneId(_ => "")
        } else {
          let currentViewerSceneId =
            ViewerSystem.Adapter.getMetaData(viewer, "sceneId")->sceneIdFromMeta
          let rect = Dom.getBoundingClientRect(svg)
          if rect.width > 0.0 && currentViewerSceneId != "" {
            let yaw = Viewer.getYaw(viewer)
            let pitch = Viewer.getPitch(viewer)
            let hfov = Viewer.getHfov(viewer)

            let newCam = ProjectionMath.makeCamState(yaw, pitch, hfov, rect)
            setCam(_ => Some(newCam))
            setContainerRect(_ => Some(rect))
            setViewerSceneId(_ => currentViewerSceneId)
          } else {
            setCam(_ => None)
            setContainerRect(_ => None)
            setViewerSceneId(_ => "")
          }
        }
      | _ =>
        setCam(_ => None)
        setContainerRect(_ => None)
        setViewerSceneId(_ => "")
      }
      animationFrameId := Some(Window.requestAnimationFrame(loop))
    }

    animationFrameId := Some(Window.requestAnimationFrame(loop))

    Some(
      () => {
        switch animationFrameId.contents {
        | Some(id) => Window.cancelAnimationFrame(id)
        | None => ()
        }
      },
    )
  })

  if isTeasing {
    React.null
  } else {
    let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    let currentScene = Belt.Array.get(activeScenes, state.activeIndex)

    <div
      id="react-hotspot-layer"
      className="absolute inset-0 z-[6000] pointer-events-none overflow-hidden"
    >
      {switch (currentScene, cam, containerRect) {
      | (Some(scene), Some(camState), Some(rect)) =>
        if viewerSceneId != scene.id {
          React.null
        } else {
          scene.hotspots
          ->Belt.Array.mapWithIndex((i, h) => {
            let isMovingThis = switch state.movingHotspot {
            | Some(mh) => mh.sceneIndex == state.activeIndex && mh.hotspotIndex == i
            | None => false
            }

            let (pitch, yaw) = if isMovingThis {
              switch ViewerState.state.contents.lastMouseEvent->Nullable.toOption {
              | Some(ev) =>
                let v = ViewerSystem.getActiveViewer()
                switch Nullable.toOption(v) {
                | Some(viewer) =>
                  let mouseEvent: Viewer.mouseEvent = {
                    "clientX": Belt.Int.toFloat(Dom.clientX(ev)),
                    "clientY": Belt.Int.toFloat(Dom.clientY(ev)),
                  }
                  let coords = Viewer.mouseEventToCoords(viewer, mouseEvent)
                  let p = Belt.Array.get(coords, 0)->Option.getOr(h.pitch)
                  let y = Belt.Array.get(coords, 1)->Option.getOr(h.yaw)
                  (p, y)
                | None => (h.pitch, h.yaw)
                }
              | None => (h.pitch, h.yaw)
              }
            } else {
              (h.pitch, h.yaw)
            }

            let coords = ProjectionMath.getScreenCoords(camState, pitch, yaw, rect)

            switch coords {
            | Some(c) =>
              let elementId = "hs-react-" ++ h.linkId
              let isAutoForward = h.isAutoForward->Option.getOr(false)

              <div
                key={h.linkId}
                className={`absolute ${isMovingThis ? "pointer-events-none" : "pointer-events-auto"}`}
                style={makeStyle({
                  "left": Math.round(c.x)->Float.toString ++ "px",
                  "top": Math.round(c.y)->Float.toString ++ "px",
                })}
              >
                <PreviewArrow
                  sceneIndex={state.activeIndex}
                  hotspotIndex={i}
                  dispatch={dispatch}
                  elementId={elementId}
                  isTargetAutoForward={isAutoForward}
                  scenes={activeScenes}
                  state={state}
                />
              </div>
            | None => React.null
            }
          })
          ->React.array
        }
      | _ => React.null
      }}
    </div>
  }
})
