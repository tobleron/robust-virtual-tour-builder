open Types

let buildManifest = (state: state, ~skipAutoForward: bool, ~includeIntroPan: bool): result<
  motionManifest,
  string,
> => {
  let baseManifest = TeaserManifest.generateSimulationParityManifest(
    state,
    ~skipAutoForward,
    ~includeIntroPan,
  )
  let manifest = {
    ...baseManifest,
    shots: baseManifest.shots->Belt.Array.mapWithIndex((idx, shot) => {
      if idx == 0 {
        shot
      } else {
        {...shot, waitBeforePanMs: 0}
      }
    }),
  }
  if Belt.Array.length(manifest.shots) == 0 {
    Error("No teaser shots available")
  } else {
    Ok(manifest)
  }
}
