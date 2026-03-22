/* src/components/ReactHotspotLayerSupport.res */
open ReBindings
open Types

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

let deriveDuplicateStackPlacements = (seeds: array<duplicateStackSeed>): Belt.Map.String.t<
  duplicateStackPlacement,
> => {
  let initialGroups: Belt.Map.String.t<duplicateTargetGroup> = Belt.Map.String.empty
  let initialPlacements: Belt.Map.String.t<duplicateStackPlacement> = Belt.Map.String.empty
  let (_, placements) = seeds->Belt.Array.reduce((initialGroups, initialPlacements), (
    (groups, placements),
    seed,
  ) =>
    switch seed.targetSceneId {
    | Some(targetSceneId) if targetSceneId != "" =>
      switch groups->Belt.Map.String.get(targetSceneId) {
      | Some(group) =>
        let nextGroups = groups->Belt.Map.String.set(
          targetSceneId,
          {
            anchorLinkId: group.anchorLinkId,
            nextStackIndex: group.nextStackIndex + 1,
          },
        )
        let nextPlacements = placements->Belt.Map.String.set(
          seed.linkId,
          {
            anchorLinkId: group.anchorLinkId,
            stackIndex: group.nextStackIndex,
          },
        )
        (nextGroups, nextPlacements)
      | None =>
        let nextGroups = groups->Belt.Map.String.set(
          targetSceneId,
          {
            anchorLinkId: seed.linkId,
            nextStackIndex: 1,
          },
        )
        let nextPlacements = placements->Belt.Map.String.set(
          seed.linkId,
          {
            anchorLinkId: seed.linkId,
            stackIndex: 0,
          },
        )
        (nextGroups, nextPlacements)
      }
    | _ => (groups, placements)
    }
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

let resolveMovingHotspotPitchYaw = (~state, ~hotspot: hotspot, ~hotspotIndex: int) => {
  let isMovingThis = switch state.movingHotspot {
  | Some(mh) => mh.sceneIndex == state.activeIndex && mh.hotspotIndex == hotspotIndex
  | None => false
  }

  if !isMovingThis {
    (hotspot.pitch, hotspot.yaw)
  } else {
    switch ViewerState.state.contents.lastMouseEvent->Nullable.toOption {
    | Some(ev) =>
      switch Nullable.toOption(ViewerSystem.getActiveViewer()) {
      | Some(viewer) =>
        let mouseEvent: Viewer.mouseEvent = {
          "clientX": Belt.Int.toFloat(Dom.clientX(ev)),
          "clientY": Belt.Int.toFloat(Dom.clientY(ev)),
        }
        let coords = Viewer.mouseEventToCoords(viewer, mouseEvent)
        let p = Belt.Array.get(coords, 0)->Option.getOr(hotspot.pitch)
        let y = Belt.Array.get(coords, 1)->Option.getOr(hotspot.yaw)
        (p, y)
      | None => (hotspot.pitch, hotspot.yaw)
      }
    | None => (hotspot.pitch, hotspot.yaw)
    }
  }
}

let isMovingThisHotspot = (~state, ~hotspotIndex: int) =>
  switch state.movingHotspot {
  | Some(mh) => mh.sceneIndex == state.activeIndex && mh.hotspotIndex == hotspotIndex
  | None => false
  }

let projectHotspot = (
  ~state,
  ~activeScenes: array<scene>,
  ~camState,
  ~rect,
  ~hotspotBadgeByLinkId,
  ~sceneNumberBySceneId,
  ~hotspot: hotspot,
  ~hotspotIndex: int,
) => {
  let isMovingThis = isMovingThisHotspot(~state, ~hotspotIndex)
  let (pitch, yaw) = resolveMovingHotspotPitchYaw(~state, ~hotspot, ~hotspotIndex)
  let resolvedTargetSceneId = HotspotTarget.resolveSceneId(activeScenes, hotspot)
  let coords = ProjectionMath.getScreenCoords(camState, pitch, yaw, rect)
  let labelText = resolvedTargetSceneId->Option.flatMap(targetSceneId =>
    activeScenes
    ->Belt.Array.getBy(scene => scene.id == targetSceneId)
    ->Option.map(sceneDisplayLabel)
  )
  let badge = hotspotBadgeByLinkId->Belt.Map.String.get(hotspot.linkId)
  let targetSceneNumber =
    resolvedTargetSceneId->Option.flatMap(targetSceneId =>
      sceneNumberBySceneId->Belt.Map.String.get(targetSceneId)
    )

  {
    hotspot,
    hotspotIndex,
    isMovingThis,
    coords,
    labelText,
    badge,
    targetSceneNumber,
    targetSceneId: resolvedTargetSceneId,
  }
}

let isHiddenByHoveredSibling = (
  ~hoveredStackHotspotLinkId,
  ~hotspotGroupAnchorLinkId: string,
  ~duplicateStackPlacements: Belt.Map.String.t<duplicateStackPlacement>,
  ~hotspotLinkId: string,
): bool => {
  switch hoveredStackHotspotLinkId {
  | Some(hoveredLinkId) =>
    let hoveredGroupAnchorLinkId = resolveDuplicateGroupAnchorLinkId(
      hoveredLinkId,
      duplicateStackPlacements,
    )
    hoveredLinkId != hotspotLinkId && hoveredGroupAnchorLinkId == hotspotGroupAnchorLinkId
  | None => false
  }
}
