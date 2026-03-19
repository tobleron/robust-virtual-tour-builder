open Types

let resolveAutoForwardHotspotIndex = (rawHotspots: array<TourData.hotspotData>, hasSceneId: string => bool) => {
  let autoForwardHotspotIndex = rawHotspots->Belt.Array.getIndexBy(h =>
    h["targetIsAutoForward"] == true && hasSceneId(h["targetSceneId"])
  )
  let autoForwardTargetSceneId = switch autoForwardHotspotIndex {
  | Some(idx) =>
    rawHotspots
    ->Belt.Array.get(idx)
    ->Option.map(h => h["targetSceneId"])
    ->Option.getOr("")
  | None => ""
  }
  (autoForwardHotspotIndex->Option.getOr(-1), autoForwardTargetSceneId)
}

let resolveTargetSceneId = (~targetSceneId: option<string>, ~target: string, ~scenes: array<scene>, ~hasSceneId: string => bool) =>
  switch targetSceneId {
  | Some(sceneId) =>
    if hasSceneId(sceneId) {
      sceneId
    } else {
      switch TourData.resolveSceneIdFromTargetRef(sceneId, scenes) {
      | Some(id) => id
      | None => TourData.resolveSceneIdFromTargetRef(target, scenes)->Option.getOr("")
      }
    }
  | None => TourData.resolveSceneIdFromTargetRef(target, scenes)->Option.getOr("")
  }

let normalizeExportType = exportType => {
  let normalizedExportType = switch exportType {
  | "desktop_blob_hd_landscape_touch" => "hd"
  | "desktop_blob_2k" => "2k"
  | "desktop_blob_2k_landscape_touch" => "2k"
  | "desktop_blob_4k_landscape_touch" => "4k"
  | other => other
  }
  let allowFileProtocol =
    exportType == "desktop_blob_2k" ||
    exportType == "desktop_blob_hd_landscape_touch" ||
    exportType == "desktop_blob_2k_landscape_touch" ||
    exportType == "desktop_blob_4k_landscape_touch"
  let forcedExportInteractionShell = switch exportType {
  | "desktop_blob_hd_landscape_touch" | "desktop_blob_2k_landscape_touch" => "landscape-touch"
  | "desktop_blob_4k_landscape_touch" => "landscape-touch"
  | _ => ""
  }
  (normalizedExportType, allowFileProtocol, forcedExportInteractionShell)
}

let buildExportHotspotEntry = (
  ~sceneId: string,
  ~hotspotIndex: int,
  ~hotspot: Types.hotspot,
  ~resolvedTargetId: string,
  ~targetSceneNumber: option<int>,
  ~hasValidTarget: bool,
  ~isReturnLink: bool,
  ~sequenceNumber: option<int>,
): option<TourTemplateHtmlSupportData.exportHotspotEntry> =>
  switch hasValidTarget {
  | false => None
  | true =>
    let targetIsAutoForward = switch hotspot.isAutoForward {
    | Some(true) => true
    | _ => false
    }
    let hotspotData: TourData.hotspotData = {
      "pitch": hotspot.displayPitch->Option.getOr(hotspot.pitch),
      "yaw": hotspot.yaw,
      "target": hotspot.target,
      "targetSceneId": resolvedTargetId,
      "targetSceneNumber": targetSceneNumber->Nullable.fromOption,
      "targetIsAutoForward": targetIsAutoForward,
      "isReturnLink": isReturnLink,
      "sequenceNumber": sequenceNumber->Nullable.fromOption,
      "startYaw": hotspot.startYaw->Nullable.fromOption,
      "startPitch": hotspot.startPitch->Nullable.fromOption,
      "waypoints": hotspot.waypoints->Nullable.fromOption,
      "truePitch": hotspot.pitch,
      "viewFrame": hotspot.viewFrame->Nullable.fromOption,
      "targetYaw": hotspot.targetYaw->Nullable.fromOption,
      "targetPitch": hotspot.targetPitch->Nullable.fromOption,
    }
    Some({
      sourceSceneId: sceneId,
      hotspotIndex,
      linkId: hotspot.linkId,
      destinationKey: TourTemplateHtmlSupportData.exportHotspotDestinationKey(hotspotData),
      isReturnLink,
      sequenceNumber,
      hotspotData,
    })
  }

let buildSequencingState = (scenes: array<scene>): state =>
  if Belt.Array.length(scenes) == 0 {
    State.initialState
  } else {
    {
      ...State.initialState,
      inventory: scenes->Belt.Array.reduce(Belt.Map.String.empty, (acc, scene) =>
        acc->Belt.Map.String.set(scene.id, {scene, status: Active})
      ),
      sceneOrder: scenes->Belt.Array.map(scene => scene.id),
      activeIndex: 0,
    }
  }
