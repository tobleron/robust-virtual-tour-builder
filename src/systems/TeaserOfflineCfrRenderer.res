open ReBindings
open Types

module Recorder = TeaserRecorder.Recorder
module Playback = TeaserPlayback
module Manifest = TeaserManifest

let normalizeSceneFloor = (floorRaw: string): option<string> => {
  let trimmed = floorRaw->String.trim
  if trimmed == "" {
    None
  } else {
    Some(trimmed)
  }
}

let floorLevelsInUse = (scenes: array<scene>): array<string> => {
  let inUse = Dict.make()
  scenes->Belt.Array.forEach(scene =>
    normalizeSceneFloor(scene.floor)->Option.forEach(floorId => Dict.set(inUse, floorId, true))
  )
  Constants.Scene.floorLevels->Belt.Array.keepMap(level =>
    switch Dict.get(inUse, level.id) {
    | Some(true) => Some(level.id)
    | _ => None
    }
  )
}

let signalIsAborted = signal =>
  switch signal {
  | Some(sig) => BrowserBindings.AbortSignal.aborted(sig)
  | None => false
  }

let throwIfCancelled = (~signal: option<BrowserBindings.AbortSignal.t>=?) =>
  signal->Option.forEach(sig => {
    if BrowserBindings.AbortSignal.aborted(sig) {
      JsError.throwWithMessage("AbortError")
    }
  })

let formatEta = (etaMs: float) => {
  let seconds = Belt.Float.toInt(etaMs /. 1000.0)
  if seconds <= 0 {
    "Almost done"
  } else {
    let m = seconds / 60
    let s = mod(seconds, 60)
    if m > 0 {
      "ETA " ++ Belt.Int.toString(m) ++ "m " ++ Belt.Int.toString(s) ++ "s"
    } else {
      "ETA " ++ Belt.Int.toString(s) ++ "s"
    }
  }
}

let sceneOverlayFor = (
  scenes: array<scene>,
  sceneId: string,
  visibleFloorIds: array<string>,
): TeaserRecorder.teaserHudOverlay =>
  scenes
  ->Belt.Array.getBy(scene => scene.id == sceneId)
  ->Option.map((scene): TeaserRecorder.teaserHudOverlay => {
    roomLabel: if scene.label->String.trim == "" {
      None
    } else {
      Some(scene.label)
    },
    activeFloor: if scene.floor->String.trim == "" {
      "ground"
    } else {
      scene.floor
    },
    visibleFloorIds,
  })
  ->Option.getOr(
    (
      {
        roomLabel: None,
        activeFloor: "ground",
        visibleFloorIds,
      }: TeaserRecorder.teaserHudOverlay
    ),
  )

let renderWebMDeterministic = async (
  manifest: motionManifest,
  includeLogo: bool,
  ~getState: unit => state,
  ~dispatch: Actions.action => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onProgress: option<(float, string, string) => unit>=?,
) => {
  let state = getState()
  let logoState = await Recorder.loadLogo(state.logo)
  let fps = if manifest.fps > 0 {
    manifest.fps->Belt.Int.toFloat
  } else {
    Constants.Teaser.frameRate->Belt.Int.toFloat
  }
  let targetFrameDurationMs = 1000.0 /. fps
  let totalDurationMs = Manifest.calculateTotalManifestDuration(manifest)
  let totalFrames = Belt.Float.toInt(totalDurationMs /. 1000.0 *. fps)

  if Recorder.startRecording(~deterministic=true, ()) {
    let state = getState()
    let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    let visibleFloorIds = floorLevelsInUse(scenes)
    let currentSceneId = ref("")
    let benchmarkFrames = Constants.Teaser.Processing.preflightSampleFrames
    let rollingThroughput = ref(0.0)

    for frameIndex in 0 to totalFrames {
      throwIfCancelled(~signal?)
      let frameStart = Date.now()
      let t = Belt.Int.toFloat(frameIndex) /. fps *. 1000.0
      let frameState = Playback.getManifestStateAt(manifest, t)

      let isBenchmarking = frameIndex < benchmarkFrames
      let phaseName = isBenchmarking ? "Benchmarking" : "Rendering Frames"

      if frameState.sceneId != currentSceneId.contents {
        if currentSceneId.contents != "" {
          Recorder.internalState.contents.ghostCanvas->Option.forEach(Recorder.setSnapshot)
        }
        currentSceneId := frameState.sceneId
        let idx =
          scenes->Belt.Array.getIndexBy(s => s.id == currentSceneId.contents)->Option.getOr(0)
        dispatch(Actions.SetActiveScene(idx, frameState.pose.yaw, frameState.pose.pitch, None))
        let _ = await Playback.waitForViewerReady(currentSceneId.contents)
      }

      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, frameState.pose.yaw, false)
        Viewer.setPitch(v, frameState.pose.pitch, false)
        Viewer.setHfov(v, frameState.pose.hfov, false)
      })

      Recorder.setFadeOpacity(frameState.fadeOpacity)

      switch Dom.querySelector(
        Dom.documentBody,
        ".panorama-layer.active canvas",
      )->Nullable.toOption {
      | Some(sc) =>
        let overlay = sceneOverlayFor(scenes, frameState.sceneId, visibleFloorIds)
        Recorder.renderFrame(sc, includeLogo, logoState, ~overlay)
        Recorder.requestDeterministicFrame()
      | None => ()
      }

      let workDuration = Date.now() -. frameStart
      let remainingFrameBudget = targetFrameDurationMs -. workDuration
      if remainingFrameBudget > 0.0 {
        await Playback.wait(Math.Int.max(1, Belt.Float.toInt(remainingFrameBudget)))
      }

      let actualDuration = Date.now() -. frameStart
      if frameIndex == 0 {
        rollingThroughput := actualDuration
      } else {
        let alpha = Constants.Teaser.Processing.progressSmoothingAlpha
        rollingThroughput := rollingThroughput.contents *. (1.0 -. alpha) +. actualDuration *. alpha
      }

      if mod(frameIndex, 12) == 0 || isBenchmarking {
        let pct = Belt.Int.toFloat(frameIndex) /. Belt.Int.toFloat(totalFrames) *. 100.0
        let framesLeft = totalFrames - frameIndex
        let etaMs = Belt.Int.toFloat(framesLeft) *. rollingThroughput.contents
        let etaStr = frameIndex > 0 ? formatEta(etaMs) : "Estimating..."
        onProgress->Option.forEach(cb =>
          cb(
            pct,
            "Rendering frame " ++
            Belt.Int.toString(frameIndex) ++
            " / " ++
            Belt.Int.toString(totalFrames) ++
            "|" ++
            etaStr,
            phaseName,
          )
        )
      }
    }

    onProgress->Option.forEach(cb => cb(98.0, "Encoding container...|Almost done", "Encoding WebM"))
    Recorder.stopRecording()
    await Playback.wait(500)
    true
  } else {
    false
  }
}
