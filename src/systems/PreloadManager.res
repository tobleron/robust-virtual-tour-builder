/* src/systems/PreloadManager.res */

open Types
open Actions

let topNDefault = 3
let preloadedRecentlyRef: ref<array<string>> = ref([])
let visitFrequencyRef: ref<dict<int>> = ref(Dict.make())

let getViewerYaw = (): float => {
  switch ViewerSystem.getActiveViewer()->Nullable.toOption {
  | Some(v) => ViewerSystem.Adapter.getYaw(v)
  | None => 0.0
  }
}

let normalizeYaw = (yaw: float): float => {
  let y = ref(yaw)
  while y.contents > 180.0 {
    y := y.contents -. 360.0
  }
  while y.contents < -180.0 {
    y := y.contents +. 360.0
  }
  y.contents
}

let angularDistance = (a: float, b: float): float => {
  let d = Math.abs(normalizeYaw(a -. b))
  if d > 180.0 {
    360.0 -. d
  } else {
    d
  }
}

let memoryPressureHigh = (): bool =>
  %raw(`(() => {
    try {
      if (typeof performance === "undefined" || !performance || !performance.memory) return false;
      const mem = performance.memory;
      const used = Number(mem.usedJSHeapSize || 0);
      const limit = Number(mem.jsHeapSizeLimit || 0);
      if (!Number.isFinite(used) || !Number.isFinite(limit) || limit <= 0) return false;
      return (used / limit) >= 0.7;
    } catch (_) {
      return false;
    }
  })()`)

let shouldSkipPreload = (state: state): bool => {
  let densityLevel = StateDensityMonitor.toSnapshot(state).level
  switch densityLevel {
  | High => true
  | _ => memoryPressureHigh()
  }
}

let updateVisitFrequency = (activeIndex: int) => {
  let key = Belt.Int.toString(activeIndex)
  let current = Dict.get(visitFrequencyRef.contents, key)->Option.getOr(0)
  Dict.set(visitFrequencyRef.contents, key, current + 1)
}

let connectednessScore = (scene: scene): float => Belt.Array.length(scene.hotspots)->Int.toFloat *. 0.05

let directionScore = (~viewerYaw: float, ~hotspotYaw: float): float => {
  let dist = angularDistance(viewerYaw, hotspotYaw)
  (180.0 -. dist) /. 180.0
}

let historyScore = (sceneIndex: int): float => {
  let key = Belt.Int.toString(sceneIndex)
  Dict.get(visitFrequencyRef.contents, key)->Option.getOr(0)->Int.toFloat *. 0.1
}

let rankCandidates = (scenes: array<scene>, activeIndex: int): array<int> => {
  switch Belt.Array.get(scenes, activeIndex) {
  | None => []
  | Some(activeScene) =>
    let viewerYaw = getViewerYaw()
    let ranked =
      activeScene.hotspots
      ->Belt.Array.keepMap(h =>
        h.targetSceneId
        ->Option.flatMap(targetId => scenes->Belt.Array.getIndexBy(s => s.id == targetId))
        ->Option.flatMap(targetIdx =>
          scenes->Belt.Array.get(targetIdx)->Option.map(targetScene => {
            let score =
            directionScore(~viewerYaw, ~hotspotYaw=h.yaw) +.
            connectednessScore(targetScene) +.
            historyScore(targetIdx)
            (targetIdx, score)
          })
        )
      )
    let _ =
      ranked->Array.sort(((idxA, scoreA), (idxB, scoreB)) =>
        if scoreA > scoreB {
          -1.
        } else if scoreA < scoreB {
          1.
        } else {
          Int.toFloat(compare(idxA, idxB))
        }
      )
    ranked->Belt.Array.map(((idx, _score)) => idx)
  }
}

let usePredictivePreload = (~state: state, ~dispatch: action => unit) => {
  React.useEffect2(() => {
    let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    let activeIndex = state.activeIndex

    if activeIndex >= 0 && activeIndex < Belt.Array.length(scenes) {
      updateVisitFrequency(activeIndex)
    }

    if !shouldSkipPreload(state) {
      let candidates = rankCandidates(scenes, activeIndex)
      let topN = Belt.Array.slice(candidates, ~offset=0, ~len=topNDefault)
      topN
      ->Belt.Array.forEach(targetIdx => {
        switch Belt.Array.get(scenes, targetIdx) {
        | Some(targetScene) =>
          let alreadyQueued = preloadedRecentlyRef.contents->Belt.Array.some(id => id == targetScene.id)
          if !alreadyQueued && targetIdx != activeIndex {
            preloadedRecentlyRef := Belt.Array.concat(preloadedRecentlyRef.contents, [targetScene.id])
            let keepOffset = {
              let len = Belt.Array.length(preloadedRecentlyRef.contents)
              if len > 12 {
                len - 12
              } else {
                0
              }
            }
            let keepLen = Belt.Array.length(preloadedRecentlyRef.contents) - keepOffset
            preloadedRecentlyRef := Belt.Array.slice(
              preloadedRecentlyRef.contents,
              ~offset=keepOffset,
              ~len=keepLen,
            )
            dispatch(SetPreloadingScene(targetIdx))
          }
        | None => ()
        }
      })
    }

    None
  }, (state.activeIndex, state.structuralRevision))
}
