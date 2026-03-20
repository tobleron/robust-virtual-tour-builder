open ReBindings
open Types
include ReactHotspotLayerSupport

module OpTypes = OperationLifecycleTypes

module OpContext = OperationLifecycleContext

let cleanSceneTag = raw => ReactHotspotLayerSupport.cleanSceneTag(raw)
let sceneDisplayLabel = scene => ReactHotspotLayerSupport.sceneDisplayLabel(scene)
let sceneIdFromMeta = meta => ReactHotspotLayerSupport.sceneIdFromMeta(meta)
let duplicateTargetStackSpacingPx = ReactHotspotLayerSupport.duplicateTargetStackSpacingPx
let duplicateStackRestoreDelayMs = ReactHotspotLayerSupport.duplicateStackRestoreDelayMs
let deriveDuplicateStackPlacements = seeds =>
  ReactHotspotLayerSupport.deriveDuplicateStackPlacements(seeds)
let resolveStackedCoords = (hotspotData, placementByLinkId, hotspotByLinkId) =>
  ReactHotspotLayerSupport.resolveStackedCoords(hotspotData, placementByLinkId, hotspotByLinkId)
let shouldShowHotspotLabel = (hotspotData, placementByLinkId, showHotspotLabels) =>
  ReactHotspotLayerSupport.shouldShowHotspotLabel(
    hotspotData,
    placementByLinkId,
    showHotspotLabels,
  )
let resolveDuplicateGroupAnchorLinkId = (linkId, placementByLinkId) =>
  ReactHotspotLayerSupport.resolveDuplicateGroupAnchorLinkId(linkId, placementByLinkId)
let clearHoveredStackRestoreTimer = timerRef =>
  ReactHotspotLayerSupport.clearHoveredStackRestoreTimer(timerRef)
let resolveViewerSceneId = viewer => {
  let metaSceneId = ViewerSystem.Adapter.getMetaData(viewer, "sceneId")->sceneIdFromMeta
  if metaSceneId != "" {
    metaSceneId
  } else {
    try {
      ViewerSystem.Adapter.getScene(viewer)
    } catch {
    | _ => ""
    }
  }
}
let clearHoveredHotspotRestoreTimer = (timerRef: React.ref<option<int>>) => {
  switch timerRef.current {
  | Some(id) => ReBindings.Window.clearTimeout(id)
  | None => ()
  }
  timerRef.current = None
}
let resolveMovingHotspotPitchYaw = (~state, ~hotspot, ~hotspotIndex) =>
  ReactHotspotLayerSupport.resolveMovingHotspotPitchYaw(
    ~state,
    ~hotspot,
    ~hotspotIndex,
  )
let isMovingThisHotspot = (~state, ~hotspotIndex) =>
  ReactHotspotLayerSupport.isMovingThisHotspot(~state, ~hotspotIndex)
let projectHotspot = (
  ~state,
  ~activeScenes,
  ~camState,
  ~rect,
  ~hotspotBadgeByLinkId,
  ~sceneNumberBySceneId,
  ~hotspot,
  ~hotspotIndex,
) =>
  ReactHotspotLayerSupport.projectHotspot(
    ~state,
    ~activeScenes,
    ~camState,
    ~rect,
    ~hotspotBadgeByLinkId,
    ~sceneNumberBySceneId,
    ~hotspot,
    ~hotspotIndex,
  )
let isHiddenByHoveredSibling = (
  ~hoveredStackHotspotLinkId,
  ~hotspotGroupAnchorLinkId,
  ~duplicateStackPlacements,
  ~hotspotLinkId,
) =>
  ReactHotspotLayerSupport.isHiddenByHoveredSibling(
    ~hoveredStackHotspotLinkId,
    ~hotspotGroupAnchorLinkId,
    ~duplicateStackPlacements,
    ~hotspotLinkId,
  )

external makeStyle: {..} => ReactDOM.Style.t = "%identity"

let renderHotspotCard = (
  ~state: state,
  ~dispatch,
  ~activeScenes: array<scene>,
  ~showHotspotLabels: bool,
  ~duplicateStackPlacements: Belt.Map.String.t<duplicateStackPlacement>,
  ~projectedHotspot: projectedHotspot,
  ~projectedHotspotByLinkId: Belt.Map.String.t<projectedHotspot>,
  ~hoveredStackHotspotLinkId,
  ~setHoveredStackHotspotLinkId,
  ~hoveredHotspotLinkId,
  ~setHoveredHotspotLinkId,
  ~hoveredStackRestoreTimerRef,
  ~hoveredHotspotRestoreTimerRef,
) => {
  let hotspotGroupAnchorLinkId = resolveDuplicateGroupAnchorLinkId(
    projectedHotspot.hotspot.linkId,
    duplicateStackPlacements,
  )
  let renderCoords = resolveStackedCoords(
    projectedHotspot,
    duplicateStackPlacements,
    projectedHotspotByLinkId,
  )

  switch renderCoords {
  | Some(c) =>
    if isHiddenByHoveredSibling(
      ~hoveredStackHotspotLinkId,
      ~hotspotGroupAnchorLinkId,
      ~duplicateStackPlacements,
      ~hotspotLinkId=projectedHotspot.hotspot.linkId,
    ) {
      React.null
    } else {
      let h = projectedHotspot.hotspot
      let elementId = "hs-react-" ++ h.linkId
      let isAutoForward = h.isAutoForward->Option.getOr(false)
      let isDrawerOpen = hoveredHotspotLinkId == Some(h.linkId)
      let showLabelForHotspot = shouldShowHotspotLabel(
        projectedHotspot,
        duplicateStackPlacements,
        showHotspotLabels,
      )
      let (sequenceLabel, isReturnNode) = switch projectedHotspot.badge {
      | Some(HotspotSequence.Sequence(_)) => (projectedHotspot.targetSceneNumber, false)
      | Some(HotspotSequence.Return) => (None, true)
      | None => (projectedHotspot.targetSceneNumber, false)
      }
      let pinDrawerOpen = () => {
        clearHoveredHotspotRestoreTimer(hoveredHotspotRestoreTimerRef)
        setHoveredHotspotLinkId(_ => Some(h.linkId))
      }
      let scheduleDrawerClose = () => {
        clearHoveredHotspotRestoreTimer(hoveredHotspotRestoreTimerRef)
        hoveredHotspotRestoreTimerRef.current = Some(
          ReBindings.Window.setTimeout(
            () => {
              setHoveredHotspotLinkId(
                current =>
                  switch current {
                  | Some(currentLinkId) if currentLinkId == h.linkId => None
                  | _ => current
                  },
              )
              hoveredHotspotRestoreTimerRef.current = None
            },
            Constants.hotspotMenuExitDelay,
          ),
        )
      }

      <div
        key={h.linkId}
        className={`absolute ${projectedHotspot.isMovingThis
            ? "pointer-events-none"
            : "pointer-events-auto"} relative`}
        style={makeStyle({
          "left": Math.round(c.x)->Float.toString ++ "px",
          "top": Math.round(c.y)->Float.toString ++ "px",
        })}
        onMouseEnter={_ => {
          clearHoveredStackRestoreTimer(hoveredStackRestoreTimerRef)
          setHoveredStackHotspotLinkId(_ => Some(h.linkId))
          clearHoveredHotspotRestoreTimer(hoveredHotspotRestoreTimerRef)
          setHoveredHotspotLinkId(_ => None)
        }}
        onMouseLeave={_ => {
          clearHoveredStackRestoreTimer(hoveredStackRestoreTimerRef)
          hoveredStackRestoreTimerRef.current = Some(
            ReBindings.Window.setTimeout(
              () => {
                setHoveredStackHotspotLinkId(
                  current =>
                    switch current {
                    | Some(currentLinkId) if currentLinkId == h.linkId => None
                    | _ => current
                    },
                )
                hoveredStackRestoreTimerRef.current = None
              },
              duplicateStackRestoreDelayMs,
            ),
          )
          pinDrawerOpen()
          scheduleDrawerClose()
        }}
      >
        {if showLabelForHotspot {
          switch projectedHotspot.labelText {
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
          hotspotIndex={projectedHotspot.hotspotIndex}
          dispatch={dispatch}
          elementId={elementId}
          isTargetAutoForward={isAutoForward}
          sequenceLabel
          isReturnNode
          scenes={activeScenes}
          state={state}
          isDrawerOpen
          onDrawerEnter={pinDrawerOpen}
        />
      </div>
    }
  | None => React.null
  }
}

let renderHotspotOverlay = (
  ~state: state,
  ~dispatch,
  ~cam,
  ~containerRect,
  ~viewerSceneId,
  ~showHotspotLabels,
  ~hotspotBadgeByLinkId,
  ~sceneNumberBySceneId,
  ~hoveredStackHotspotLinkId,
  ~setHoveredStackHotspotLinkId,
  ~hoveredHotspotLinkId,
  ~setHoveredHotspotLinkId,
  ~hoveredStackRestoreTimerRef,
  ~hoveredHotspotRestoreTimerRef,
) => {
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
        let projectedHotspots = scene.hotspots->Belt.Array.mapWithIndex((i, h) =>
          projectHotspot(
            ~state,
            ~activeScenes,
            ~camState,
            ~rect,
            ~hotspotBadgeByLinkId,
            ~sceneNumberBySceneId,
            ~hotspot=h,
            ~hotspotIndex=i,
          ),
        )
        let duplicateStackPlacements = deriveDuplicateStackPlacements(
          projectedHotspots->Belt.Array.map(hotspotData => {
            linkId: hotspotData.hotspot.linkId,
            targetSceneId: hotspotData.targetSceneId,
          }),
        )
        let projectedHotspotByLinkId =
          projectedHotspots
          ->Belt.Array.map(hotspotData => (hotspotData.hotspot.linkId, hotspotData))
          ->Belt.Map.String.fromArray

        projectedHotspots
        ->Belt.Array.map(hotspotData =>
          renderHotspotCard(
            ~state,
            ~dispatch,
            ~activeScenes,
            ~showHotspotLabels,
            ~duplicateStackPlacements,
            ~projectedHotspot=hotspotData,
            ~projectedHotspotByLinkId,
            ~hoveredStackHotspotLinkId,
            ~setHoveredStackHotspotLinkId,
            ~hoveredHotspotLinkId,
            ~setHoveredHotspotLinkId,
            ~hoveredStackRestoreTimerRef,
            ~hoveredHotspotRestoreTimerRef,
          ),
        )
        ->React.array
      }
    | _ => React.null
    }}
  </div>
}

let useHotspotFrameState = (
  ~setCam,
  ~setContainerRect,
  ~setViewerSceneId,
  ~hoveredStackRestoreTimerRef,
  ~hoveredHotspotRestoreTimerRef,
) => {
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
          let currentViewerSceneId = resolveViewerSceneId(viewer)
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
        clearHoveredStackRestoreTimer(hoveredStackRestoreTimerRef)
        clearHoveredHotspotRestoreTimer(hoveredHotspotRestoreTimerRef)
      },
    )
  })
}

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
  let (hoveredStackHotspotLinkId, setHoveredStackHotspotLinkId) = React.useState(_ => None)
  let hoveredStackRestoreTimerRef: React.ref<option<int>> = React.useRef(None)
  let (hoveredHotspotLinkId, setHoveredHotspotLinkId) = React.useState(_ => None)
  let hoveredHotspotRestoreTimerRef: React.ref<option<int>> = React.useRef(None)
  useHotspotFrameState(
    ~setCam,
    ~setContainerRect,
    ~setViewerSceneId,
    ~hoveredStackRestoreTimerRef,
    ~hoveredHotspotRestoreTimerRef,
  )

  if isTeasing {
    React.null
  } else {
    renderHotspotOverlay(
      ~state,
      ~dispatch,
      ~cam,
      ~containerRect,
      ~viewerSceneId,
      ~showHotspotLabels,
      ~hotspotBadgeByLinkId,
      ~sceneNumberBySceneId,
      ~hoveredStackHotspotLinkId,
      ~setHoveredStackHotspotLinkId,
      ~hoveredHotspotLinkId,
      ~setHoveredHotspotLinkId,
      ~hoveredStackRestoreTimerRef,
      ~hoveredHotspotRestoreTimerRef,
    )
  }
})
