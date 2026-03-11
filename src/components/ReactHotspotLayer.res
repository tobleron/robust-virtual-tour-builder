/* src/components/ReactHotspotLayer.res */
open ReBindings
open Types

module OpTypes = OperationLifecycleTypes

module OpContext = OperationLifecycleContext

let cleanSceneTag = raw => {
  let trimmed = raw->String.trim
  if trimmed == "" {
    ""
  } else if String.startsWith(trimmed, "#") {
    trimmed
    ->String.substring(~start=1, ~end=String.length(trimmed))
    ->String.trim
  } else {
    trimmed
  }
}

let sceneDisplayLabel = (scene: scene) => {
  let source = if scene.label->String.trim != "" {
    scene.label
  } else {
    scene.name
  }
  let cleaned = cleanSceneTag(source)
  if cleaned->String.toLowerCase->String.includes("untagged") {
    ""
  } else {
    cleaned
  }
}

external makeStyle: {..} => ReactDOM.Style.t = "%identity"
external unknownToString: unknown => string = "%identity"
let sceneIdFromMeta = meta => meta->Option.map(unknownToString)->Option.getOr("")

@react.component
let make = React.memo(() => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let uiSlice = AppContext.useUiSlice()
  let isTeasing = uiSlice.isTeasing
  let operations = OperationLifecycle.useOperations()
  let opIsActive = type_ =>
    operations->Belt.Array.some(task => {
      OpContext.isActiveStatus(task.status) && task.type_ == type_
    })
  let uploadActive = opIsActive(OpTypes.Upload)
  let exportActive = opIsActive(OpTypes.Export)
  let teaserActive = opIsActive(OpTypes.Teaser)
  let operationBusy = uploadActive || exportActive || teaserActive
  let simulationActive = switch state.simulation.status {
  | Idle => false
  | _ => true
  }
  let showHotspotLabels = !isTeasing && !operationBusy && !simulationActive
  let hotspotBadgeByLinkId = React.useMemo1(
    () => HotspotSequence.deriveBadgeByLinkId(~state),
    [state.structuralRevision],
  )
  let sceneNumberBySceneId = React.useMemo1(
    () => HotspotSequence.deriveSceneNumberBySceneId(~state),
    [state.structuralRevision],
  )

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
              let labelText = switch h.targetSceneId {
              | Some(targetId) =>
                activeScenes
                ->Belt.Array.getBy(scene => scene.id == targetId)
                ->Option.map(sceneDisplayLabel)
              | None => None
              }
              let badge = hotspotBadgeByLinkId->Belt.Map.String.get(h.linkId)
              let targetSceneNumber =
                HotspotTarget.resolveSceneId(activeScenes, h)->Option.flatMap(targetSceneId =>
                  sceneNumberBySceneId->Belt.Map.String.get(targetSceneId)
                )
              let (sequenceLabel, isReturnNode) = switch badge {
              | Some(HotspotSequence.Sequence(_)) => (targetSceneNumber, false)
              | Some(HotspotSequence.Return) => (None, true)
              | None => (targetSceneNumber, false)
              }

              <div
                key={h.linkId}
                className={`absolute ${isMovingThis
                    ? "pointer-events-none"
                    : "pointer-events-auto"} relative`}
                style={makeStyle({
                  "left": Math.round(c.x)->Float.toString ++ "px",
                  "top": Math.round(c.y)->Float.toString ++ "px",
                })}
              >
                {if showHotspotLabels {
                  switch labelText {
                  | Some(label) if label != "" =>
                    <div className="hs-hotspot-label pointer-events-none">
                      {React.string(label)}
                    </div>
                  | _ => React.null
                  }
                } else {
                  React.null
                }}
                <PreviewArrow
                  sceneIndex={state.activeIndex}
                  hotspotIndex={i}
                  dispatch={dispatch}
                  elementId={elementId}
                  isTargetAutoForward={isAutoForward}
                  sequenceLabel
                  isReturnNode
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
