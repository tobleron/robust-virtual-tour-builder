open Types

type teaserConfig = {clipDuration: float, transitionDuration: float, cameraPanOffset: float}

type panSpeedOption = {
  id: string,
  label: string,
  description: string,
  speedDegPerSec: float,
}

let standardConfig = {clipDuration: 2500.0, transitionDuration: 1000.0, cameraPanOffset: 20.0}
let slowConfig = {clipDuration: 4000.0, transitionDuration: 1500.0, cameraPanOffset: 30.0}
let punchyConfig = {clipDuration: 1800.0, transitionDuration: 600.0, cameraPanOffset: 0.0}

let defaultPanSpeedId = "standard"

let panSpeedOptions: array<panSpeedOption> = [
  {
    id: "slow",
    label: "Slow",
    description: "15 deg/s. Longer pans for a calmer reveal.",
    speedDegPerSec: 15.0,
  },
  {
    id: defaultPanSpeedId,
    label: "Standard",
    description: "25 deg/s. Matches the current teaser pace.",
    speedDegPerSec: Constants.panningVelocity,
  },
  {
    id: "fast",
    label: "Fast",
    description: "40 deg/s. Snappier pans for shorter teasers.",
    speedDegPerSec: 40.0,
  },
]

let defaultPanSpeed = panSpeedOptions[1]->Option.getOrThrow

let getConfigForStyle = (style: string) => {
  switch style {
  | "punchy" => punchyConfig
  | "slow" => slowConfig
  | "cinematic" => slowConfig
  | _ => standardConfig
  }
}

let findPanSpeedOption = (id: string): option<panSpeedOption> =>
  panSpeedOptions->Belt.Array.getBy(opt => opt.id == id)

let resolvePanSpeedOption = (id: option<string>): panSpeedOption =>
  id->Option.flatMap(findPanSpeedOption)->Option.getOr(defaultPanSpeed)

let clampPanDuration = (durationMs: float): float =>
  Math.min(Math.max(durationMs, Constants.panningMinDuration), Constants.panningMaxDuration)

let retimePathData = (pd: pathData, panSpeed: panSpeedOption): pathData => {
  if panSpeed.speedDegPerSec <= 0.0 || panSpeed.speedDegPerSec == Constants.panningVelocity {
    pd
  } else {
    let scale = Constants.panningVelocity /. panSpeed.speedDegPerSec
    {...pd, panDuration: clampPanDuration(pd.panDuration *. scale)}
  }
}

let applyPanSpeedOption = (manifest: motionManifest, panSpeed: panSpeedOption): motionManifest => {
  if panSpeed.id == defaultPanSpeed.id {
    manifest
  } else {
    {
      ...manifest,
      shots: manifest.shots->Belt.Array.map(shot => {
        ...shot,
        pathData: shot.pathData->Option.map(pd => retimePathData(pd, panSpeed)),
      }),
    }
  }
}
