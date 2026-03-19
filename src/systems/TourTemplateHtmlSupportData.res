open Types

let escapeHtml = (raw: string): string =>
  raw
  ->String.replaceRegExp(/&/g, "&amp;")
  ->String.replaceRegExp(/</g, "&lt;")
  ->String.replaceRegExp(/>/g, "&gt;")
  ->String.replaceRegExp(/"/g, "&quot;")
  ->String.replaceRegExp(/'/g, "&#39;")

let floatKey = (value: float): string => Belt.Float.toString(value)

let nullableFloatKey = (value: Nullable.t<float>): string =>
  switch Nullable.toOption(value) {
  | Some(v) => floatKey(v)
  | None => ""
  }

let nullableViewFrameKey = (value: Nullable.t<viewFrame>): string =>
  switch Nullable.toOption(value) {
  | Some(v) => [floatKey(v.yaw), floatKey(v.pitch), floatKey(v.hfov)]->Array.join("|")
  | None => ""
  }

let nullableWaypointsKey = (value: Nullable.t<array<viewFrame>>): string =>
  switch Nullable.toOption(value) {
  | Some(waypoints) =>
    waypoints
    ->Belt.Array.map(v => [floatKey(v.yaw), floatKey(v.pitch), floatKey(v.hfov)]->Array.join("|"))
    ->Array.join(";")
  | None => ""
  }

let exportHotspotDestinationKey = (hotspot: TourData.hotspotData): string =>
  [
    hotspot["targetSceneId"],
    if hotspot["targetIsAutoForward"] {
      "1"
    } else {
      "0"
    },
    hotspot["target"],
  ]->Array.join("::")

let waypointCount = (hotspot: TourData.hotspotData): int =>
  switch Nullable.toOption(hotspot["waypoints"]) {
  | Some(waypoints) => Belt.Array.length(waypoints)
  | None => 0
  }

let sequenceValue = (hotspot: TourData.hotspotData): int =>
  switch Nullable.toOption(hotspot["sequenceNumber"]) {
  | Some(v) => v
  | None => 1_000_000
  }

let prefersExportHotspot = (
  current: TourData.hotspotData,
  candidate: TourData.hotspotData,
): bool => {
  let currentWaypointCount = waypointCount(current)
  let candidateWaypointCount = waypointCount(candidate)
  if candidate["isReturnLink"] != current["isReturnLink"] {
    candidate["isReturnLink"]
  } else if candidateWaypointCount != currentWaypointCount {
    candidateWaypointCount < currentWaypointCount
  } else {
    sequenceValue(candidate) < sequenceValue(current)
  }
}

let dedupeExportHotspots = (hotspots: array<TourData.hotspotData>): array<TourData.hotspotData> => {
  let selectedByKey = Dict.make()
  let order: array<string> = []

  hotspots->Belt.Array.forEach(hotspot => {
    let key = exportHotspotDestinationKey(hotspot)
    switch Dict.get(selectedByKey, key) {
    | Some(current) =>
      if prefersExportHotspot(current, hotspot) {
        Dict.set(selectedByKey, key, hotspot)
      }
    | None =>
      order->Array.push(key)
      Dict.set(selectedByKey, key, hotspot)
    }
  })

  order->Belt.Array.keepMap(key => Dict.get(selectedByKey, key))
}

type exportHotspotEntry = {
  sourceSceneId: string,
  hotspotIndex: int,
  linkId: string,
  destinationKey: string,
  isReturnLink: bool,
  sequenceNumber: option<int>,
  hotspotData: TourData.hotspotData,
}

let exportSceneHotspotKey = (~sceneId: string, ~hotspotIndex: int): string =>
  sceneId ++ "::" ++ Belt.Int.toString(hotspotIndex)

let deriveAutoTourManifest = (
  ~state: state,
  ~firstSceneId: string,
  ~derivedBadgeByLinkId: Belt.Map.String.t<HotspotSequence.badgeKind>,
  ~entryByLinkId,
  ~entryBySceneHotspotKey,
  ~visibleHotspotIndexByLinkId,
): TourData.autoTourManifestData => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch Belt.Array.get(activeScenes, 0) {
  | None => {
      "steps": [],
      "finalSceneId": firstSceneId,
    }
  | Some(_) =>
    let steps: array<TourData.autoTourStepData> = []
    let currentSequenceCursor = ref(0)
    let stepCount = ref(0)
    let continueLoop = ref(true)
    let finalSceneIdRef = ref(firstSceneId)
    let currentStateRef = ref({
      ...state,
      activeIndex: Constants.Scene.Sequence.startSceneIndex,
      simulation: {
        ...state.simulation,
        status: Running,
        visitedLinkIds: [],
      },
    })

    while continueLoop.contents && stepCount.contents < 400 {
      let currentState = currentStateRef.contents
      switch Belt.Array.get(activeScenes, currentState.activeIndex) {
      | Some(currentScene) =>
        finalSceneIdRef := currentScene.id
        switch SimulationMainLogic.getNextMove(currentState) {
        | SimulationMainLogic.Move({
            targetIndex,
            hotspotIndex,
            triggerActions,
            yaw: _,
            pitch: _,
            hfov: _,
          }) =>
          switch (
            Belt.Array.get(activeScenes, targetIndex),
            Belt.Array.get(currentScene.hotspots, hotspotIndex),
          ) {
          | (Some(targetScene), Some(hotspot)) =>
            finalSceneIdRef := targetScene.id
            let linkId = hotspot.linkId
            let exportEntry = switch Dict.get(entryByLinkId, linkId) {
            | Some(entry) => Some(entry)
            | None =>
              Dict.get(
                entryBySceneHotspotKey,
                exportSceneHotspotKey(~sceneId=currentScene.id, ~hotspotIndex),
              )
            }

            switch exportEntry {
            | Some(entry) =>
              let arrivalSequenceCursor = switch derivedBadgeByLinkId->Belt.Map.String.get(linkId) {
              | Some(HotspotSequence.Sequence(sequenceNo)) => sequenceNo
              | Some(HotspotSequence.Return) | None => currentSequenceCursor.contents
              }
              let visibleHotspotIndex =
                Dict.get(visibleHotspotIndexByLinkId, linkId)->Option.getOr(hotspotIndex)
              let step: TourData.autoTourStepData = {
                "sourceSceneId": currentScene.id,
                "targetSceneId": targetScene.id,
                "linkId": linkId,
                "hotspotIndex": hotspotIndex,
                "visibleHotspotIndex": visibleHotspotIndex,
                "sequenceCursor": arrivalSequenceCursor,
                "isReturnLink": entry.isReturnLink,
                "targetIsAutoForward": entry.hotspotData["targetIsAutoForward"],
                "hotspot": entry.hotspotData,
              }
              let _ = Array.push(steps, step)
              currentSequenceCursor := arrivalSequenceCursor
            | None => ()
            }

            let visitedAfterMove = TraversalSequence.applyVisitedActions(
              currentState.simulation.visitedLinkIds,
              triggerActions,
            )
            currentStateRef := {
                ...currentState,
                activeIndex: targetIndex,
                simulation: {
                  ...currentState.simulation,
                  visitedLinkIds: visitedAfterMove,
                },
              }
            stepCount := stepCount.contents + 1
          | _ => continueLoop := false
          }
        | SimulationMainLogic.Complete(_) | SimulationMainLogic.None => continueLoop := false
        }
      | None => continueLoop := false
      }
    }

    if stepCount.contents >= 400 {
      Logger.warn(
        ~module_="TourTemplateHtml",
        ~message="AUTO_TOUR_MANIFEST_MAX_STEPS_REACHED",
        ~data=Some({"maxSteps": 400}),
        (),
      )
    }

    {
      "steps": steps,
      "finalSceneId": finalSceneIdRef.contents,
    }
  }
}
