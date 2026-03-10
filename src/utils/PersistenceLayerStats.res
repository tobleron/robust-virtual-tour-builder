/* src/utils/PersistenceLayerStats.res */

type autosaveCostStats = {
  sampleCount: int,
  lastMs: float,
  averageMs: float,
  maxMs: float,
  overTargetCount: int,
}

let trimSamples = (~samples: array<float>, ~windowSize: int): array<float> => {
  if Belt.Array.length(samples) > windowSize {
    Belt.Array.sliceToEnd(samples, 1)
  } else {
    samples
  }
}

let buildAutosaveCostStats = (
  ~samples: array<float>,
  ~targetMs: float,
): autosaveCostStats => {
  let sampleCount = Belt.Array.length(samples)
  let lastMs = switch Belt.Array.get(samples, sampleCount - 1) {
  | Some(value) => value
  | None => 0.0
  }
  let totalMs = samples->Belt.Array.reduce(0.0, (acc, item) => acc +. item)
  let averageMs = if sampleCount > 0 {
    totalMs /. Float.fromInt(sampleCount)
  } else {
    0.0
  }
  let maxMs = samples->Belt.Array.reduce(0.0, (acc, item) =>
    if item > acc {
      item
    } else {
      acc
    }
  )
  let overTargetCount = samples->Belt.Array.keep(item => item > targetMs)->Belt.Array.length
  {sampleCount, lastMs, averageMs, maxMs, overTargetCount}
}

let recordAutosaveCost = (
  ~samplesRef: ref<array<float>>,
  ~durationMs: float,
  ~changedSlices: int,
  ~sceneCount: int,
  ~targetMs: float,
  ~windowSize: int,
) => {
  let nextSamples = Belt.Array.concat(samplesRef.contents, [durationMs])
  samplesRef := trimSamples(~samples=nextSamples, ~windowSize)
  let stats = buildAutosaveCostStats(~samples=samplesRef.contents, ~targetMs)

  Logger.debug(
    ~module_="Persistence",
    ~message="AUTOSAVE_MAIN_THREAD_COST",
    ~data={
      "durationMs": durationMs,
      "changedSlices": changedSlices,
      "sceneCount": sceneCount,
      "targetMs": targetMs,
      "windowSampleCount": stats.sampleCount,
      "windowAverageMs": stats.averageMs,
      "windowMaxMs": stats.maxMs,
      "windowOverTargetCount": stats.overTargetCount,
    },
    (),
  )

  if durationMs > targetMs {
    Logger.warn(
      ~module_="Persistence",
      ~message="AUTOSAVE_MAIN_THREAD_COST_ABOVE_TARGET",
      ~data={
        "durationMs": durationMs,
        "targetMs": targetMs,
      },
      (),
    )
  }
}
