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
let duplicateTargetStackSpacingPx = 42.0
let duplicateStackRestoreDelayMs = 240

type duplicateStackSeed = {
  linkId: string,
  targetSceneId: option<string>,
}

type duplicateTargetGroup = {
  anchorLinkId: string,
  nextStackIndex: int,
}

type duplicateStackPlacement = {
  anchorLinkId: string,
  stackIndex: int,
}

type projectedHotspot = {
  hotspot: hotspot,
  hotspotIndex: int,
  isMovingThis: bool,
  coords: option<screenCoords>,
  labelText: option<string>,
  badge: option<HotspotSequence.badgeKind>,
  targetSceneNumber: option<int>,
  targetSceneId: option<string>,
}

let deriveDuplicateStackPlacements = (
  seeds: array<duplicateStackSeed>,
): Belt.Map.String.t<duplicateStackPlacement> => {
  let initialGroups: Belt.Map.String.t<duplicateTargetGroup> = Belt.Map.String.empty
  let initialPlacements: Belt.Map.String.t<duplicateStackPlacement> = Belt.Map.String.empty
  let (_, placements) = seeds->Belt.Array.reduce(
    (initialGroups, initialPlacements),
    ((groups, placements), seed) =>
      switch seed.targetSceneId {
      | Some(targetSceneId) if targetSceneId != "" =>
        switch groups->Belt.Map.String.get(targetSceneId) {
        | Some(group) =>
          let nextGroups =
            groups->Belt.Map.String.set(targetSceneId, {
              anchorLinkId: group.anchorLinkId,
              nextStackIndex: group.nextStackIndex + 1,
            })
          let nextPlacements =
            placements->Belt.Map.String.set(seed.linkId, {
              anchorLinkId: group.anchorLinkId,
              stackIndex: group.nextStackIndex,
            })
          (nextGroups, nextPlacements)
        | None =>
          let nextGroups =
            groups->Belt.Map.String.set(targetSceneId, {
              anchorLinkId: seed.linkId,
              nextStackIndex: 1,
            })
          let nextPlacements =
            placements->Belt.Map.String.set(seed.linkId, {
              anchorLinkId: seed.linkId,
              stackIndex: 0,
            })
          (nextGroups, nextPlacements)
        }
      | _ => (groups, placements)
      },
  )

  placements
}

let resolveStackedCoords = (
  hotspotData: projectedHotspot,
  placementByLinkId: Belt.Map.String.t<duplicateStackPlacement>,
  hotspotByLinkId: Belt.Map.String.t<projectedHotspot>,
): option<screenCoords> => {
  switch placementByLinkId->Belt.Map.String.get(hotspotData.hotspot.linkId) {
  | Some({anchorLinkId, stackIndex}) if stackIndex > 0 && !hotspotData.isMovingThis =>
    let anchorCoords =
      hotspotByLinkId->Belt.Map.String.get(anchorLinkId)->Option.flatMap(anchor => anchor.coords)
    switch anchorCoords {
    | Some(anchor) =>
      Some({
        x: anchor.x,
        y: anchor.y +. duplicateTargetStackSpacingPx *. Belt.Int.toFloat(stackIndex),
      })
    | None => hotspotData.coords
    }
  | _ => hotspotData.coords
  }
}

let shouldShowHotspotLabel = (
  hotspotData: projectedHotspot,
  placementByLinkId: Belt.Map.String.t<duplicateStackPlacement>,
  showHotspotLabels: bool,
): bool => {
  if !showHotspotLabels {
    false
  } else {
    switch placementByLinkId->Belt.Map.String.get(hotspotData.hotspot.linkId) {
    | Some({anchorLinkId: _, stackIndex}) => stackIndex == 0
    | None => true
    }
  }
}

let resolveDuplicateGroupAnchorLinkId = (
  linkId: string,
  placementByLinkId: Belt.Map.String.t<duplicateStackPlacement>,
): string =>
  switch placementByLinkId->Belt.Map.String.get(linkId) {
  | Some({anchorLinkId, stackIndex: _}) => anchorLinkId
  | None => linkId
  }

let clearHoveredStackRestoreTimer = (timerRef: React.ref<option<int>>) => {
  switch timerRef.current {
  | Some(id) => ReBindings.Window.clearTimeout(id)
  | None => ()
  }
  timerRef.current = None
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
        clearHoveredStackRestoreTimer(hoveredStackRestoreTimerRef)
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
          let projectedHotspots = scene.hotspots->Belt.Array.mapWithIndex((i, h) => {
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

            let resolvedTargetSceneId = HotspotTarget.resolveSceneId(activeScenes, h)
            let coords = ProjectionMath.getScreenCoords(camState, pitch, yaw, rect)
            let labelText = resolvedTargetSceneId->Option.flatMap(targetSceneId =>
              activeScenes
              ->Belt.Array.getBy(scene => scene.id == targetSceneId)
              ->Option.map(sceneDisplayLabel)
            )
            let badge = hotspotBadgeByLinkId->Belt.Map.String.get(h.linkId)
            let targetSceneNumber =
              resolvedTargetSceneId->Option.flatMap(targetSceneId =>
                sceneNumberBySceneId->Belt.Map.String.get(targetSceneId)
              )

            {
              hotspot: h,
              hotspotIndex: i,
              isMovingThis,
              coords,
              labelText,
              badge,
              targetSceneNumber,
              targetSceneId: resolvedTargetSceneId,
            }
          })
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
          ->Belt.Array.map(hotspotData => {
            let hotspotGroupAnchorLinkId = resolveDuplicateGroupAnchorLinkId(
              hotspotData.hotspot.linkId,
              duplicateStackPlacements,
            )
            let hoveredGroupAnchorLinkId =
              hoveredStackHotspotLinkId->Option.map(linkId =>
                resolveDuplicateGroupAnchorLinkId(linkId, duplicateStackPlacements)
              )
            let isHiddenByHoveredSibling = switch hoveredStackHotspotLinkId {
            | Some(hoveredLinkId) =>
              hoveredLinkId != hotspotData.hotspot.linkId &&
                hoveredGroupAnchorLinkId == Some(hotspotGroupAnchorLinkId)
            | None => false
            }
            let renderCoords = resolveStackedCoords(
              hotspotData,
              duplicateStackPlacements,
              projectedHotspotByLinkId,
            )

            switch (renderCoords, isHiddenByHoveredSibling) {
            | (_, true) => React.null
            | (Some(c), false) =>
              let h = hotspotData.hotspot
              let elementId = "hs-react-" ++ h.linkId
              let isAutoForward = h.isAutoForward->Option.getOr(false)
              let showLabelForHotspot = shouldShowHotspotLabel(
                hotspotData,
                duplicateStackPlacements,
                showHotspotLabels,
              )
              let (sequenceLabel, isReturnNode) = switch hotspotData.badge {
              | Some(HotspotSequence.Sequence(_)) => (hotspotData.targetSceneNumber, false)
              | Some(HotspotSequence.Return) => (None, true)
              | None => (hotspotData.targetSceneNumber, false)
              }

              <div
                key={h.linkId}
                className={`absolute ${hotspotData.isMovingThis
                    ? "pointer-events-none"
                    : "pointer-events-auto"} relative`}
                style={makeStyle({
                  "left": Math.round(c.x)->Float.toString ++ "px",
                  "top": Math.round(c.y)->Float.toString ++ "px",
                })}
                onMouseEnter={_ => {
                  clearHoveredStackRestoreTimer(hoveredStackRestoreTimerRef)
                  setHoveredStackHotspotLinkId(_ => Some(h.linkId))
                }}
                onMouseLeave={_ =>
                  {
                    clearHoveredStackRestoreTimer(hoveredStackRestoreTimerRef)
                    hoveredStackRestoreTimerRef.current = Some(
                      ReBindings.Window.setTimeout(() => {
                        setHoveredStackHotspotLinkId(current =>
                          switch current {
                          | Some(currentLinkId) if currentLinkId == h.linkId => None
                          | _ => current
                          }
                        )
                        hoveredStackRestoreTimerRef.current = None
                      }, duplicateStackRestoreDelayMs)
                    )
                  }}
              >
                {if showLabelForHotspot {
                  switch hotspotData.labelText {
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
                  hotspotIndex={hotspotData.hotspotIndex}
                  dispatch={dispatch}
                  elementId={elementId}
                  isTargetAutoForward={isAutoForward}
                  sequenceLabel
                  isReturnNode
                  scenes={activeScenes}
                  state={state}
                />
              </div>
            | (None, false) => React.null
            }
          })
          ->React.array
        }
      | _ => React.null
      }}
    </div>
  }
})
