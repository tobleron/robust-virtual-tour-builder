/* src/utils/AsyncQueueStats.res */
// @efficiency-role: util-pure

let getHeapUsageRatio = (): option<float> =>
  %raw(`(function(){
    try {
      const p = typeof performance !== "undefined" ? performance : null;
      if (!p || !p.memory || !p.memory.jsHeapSizeLimit || p.memory.jsHeapSizeLimit <= 0) {
        return undefined;
      }
      return p.memory.usedJSHeapSize / p.memory.jsHeapSizeLimit;
    } catch (_) {
      return undefined;
    }
  })()`)

let computeStatus = (activeStatuses: Dict.t<string>, startedCount: int, total: int): string => {
  let activeCount = ref(0)
  Dict.toArray(activeStatuses)->Belt.Array.forEach(((_k, status)) => {
    if status != "__DONE__" && status != "__Error__" {
      activeCount := activeCount.contents + 1
    }
  })

  let baseMsg = "Processing " ++ Belt.Int.toString(startedCount) ++ "/" ++ Belt.Int.toString(total)
  if activeCount.contents > 0 {
    baseMsg ++ " | Active: " ++ Belt.Int.toString(activeCount.contents)
  } else {
    baseMsg
  }
}
