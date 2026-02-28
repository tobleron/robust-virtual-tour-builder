open ReBindings
open Types

module Recorder = TeaserRecorder.Recorder
module Playback = TeaserPlayback
module Manifest = TeaserManifest
external identity: 'a => 'b = "%identity"

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

let waitForViewerReadyOrAbort = async (
  sceneId: string,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  let start = Date.now()
  let rec check = async () => {
    throwIfCancelled(~signal?)
    if Date.now() -. start > 30000.0 {
      Logger.error(
        ~module_="TeaserLogic",
        ~message="WAIT_FOR_VIEWER_TIMEOUT",
        ~data=Some({"targetSceneId": sceneId}),
        (),
      )
      false
    } else {
      switch ViewerSystem.getActiveViewer()->Nullable.toOption {
      | Some(v) if Viewer.isLoaded(v) =>
        let currentId = ViewerSystem.Adapter.getMetaData(v, "sceneId")
        if currentId == Some(identity(sceneId)) {
          await Playback.wait(200)
          true
        } else {
          await Playback.wait(100)
          await check()
        }
      | _ =>
        await Playback.wait(100)
        await check()
      }
    }
  }
  await check()
}

let forceLoadSceneAndWait = async (
  sceneId: string,
  ~getState: unit => state,
  ~dispatch: Actions.action => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) => {
  throwIfCancelled(~signal?)
  let stateNow = getState()
  let activeScenesNow = SceneInventory.getActiveScenes(stateNow.inventory, stateNow.sceneOrder)
  let sourceSceneId = Belt.Array.get(activeScenesNow, stateNow.activeIndex)->Option.map(s => s.id)
  Scene.Loader.loadNewScene(
    ~state=stateNow,
    ~dispatch,
    ~sourceSceneId?,
    ~targetSceneId=sceneId,
    ~isAnticipatory=false,
    ~signal?,
  )
  await Playback.wait(220)
  await waitForViewerReadyOrAbort(sceneId, ~signal?)
}

let sceneOverlayFor = (
  scenes: array<scene>,
  sceneId: string,
  visibleFloorIds: array<string>,
  ~marketing: option<TeaserRecorder.teaserMarketingOverlay>,
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
    marketing,
  })
  ->Option.getOr(
    (
      {
        roomLabel: None,
        activeFloor: "ground",
        visibleFloorIds,
        marketing,
      }: TeaserRecorder.teaserHudOverlay
    ),
  )

let marketingOverlayFromState = (state: state): option<TeaserRecorder.teaserMarketingOverlay> => {
  let composed = MarketingText.compose(
    ~comment=state.marketingComment,
    ~phone1=state.marketingPhone1,
    ~phone2=state.marketingPhone2,
    ~forRent=state.marketingForRent,
    ~forSale=state.marketingForSale,
  )
  if composed.full != "" {
    Some({
      showRent: composed.showRent,
      showSale: composed.showSale,
      body: composed.body,
    })
  } else {
    None
  }
}

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
    let marketingOverlay = marketingOverlayFromState(state)
    let currentSceneId = ref("")
    let benchmarkFrames = Constants.Teaser.Processing.preflightSampleFrames
    let rollingThroughput = ref(0.0)

    // Deterministic teaser bootstrap: always lock the viewer to the manifest first shot
    // before frame capture starts, regardless of current editor scene.
    switch Belt.Array.get(manifest.shots, 0) {
    | Some(firstShot) =>
      let firstIdx = scenes->Belt.Array.getIndexBy(s => s.id == firstShot.sceneId)->Option.getOr(0)
      dispatch(
        Actions.SetActiveScene(
          firstIdx,
          firstShot.arrivalPose.yaw,
          firstShot.arrivalPose.pitch,
          None,
        ),
      )

      let isReady = switch ViewerSystem.getActiveViewer()->Nullable.toOption {
      | Some(v) if Viewer.isLoaded(v) =>
        let currentId = ViewerSystem.Adapter.getMetaData(v, "sceneId")
        currentId == Some(identity(firstShot.sceneId))
      | _ => false
      }

      if !isReady {
        let recovered = await forceLoadSceneAndWait(
          firstShot.sceneId,
          ~getState,
          ~dispatch,
          ~signal?,
        )
        if !recovered {
          JsError.throwWithMessage("ViewerReadyTimeout: " ++ firstShot.sceneId)
        }
      } else {
        let _ = await waitForViewerReadyOrAbort(firstShot.sceneId, ~signal?)
      }
      currentSceneId := firstShot.sceneId
    | None => ()
    }

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

        let isReady = switch ViewerSystem.getActiveViewer()->Nullable.toOption {
        | Some(v) if Viewer.isLoaded(v) =>
          let currentId = ViewerSystem.Adapter.getMetaData(v, "sceneId")
          currentId == Some(identity(currentSceneId.contents))
        | _ => false
        }

        if !isReady {
          let recovered = await forceLoadSceneAndWait(
            currentSceneId.contents,
            ~getState,
            ~dispatch,
            ~signal?,
          )
          if !recovered {
            JsError.throwWithMessage("ViewerReadyTimeout: " ++ currentSceneId.contents)
          }
        } else {
          let _ = await waitForViewerReadyOrAbort(currentSceneId.contents, ~signal?)
        }
      }

      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, frameState.pose.yaw, false)
        Viewer.setPitch(v, frameState.pose.pitch, false)
        Viewer.setHfov(v, frameState.pose.hfov, false)
      })

      Recorder.setFadeOpacity(frameState.fadeOpacity)

      switch Recorder.resolveSourceCanvas() {
      | Some(sc) =>
        let overlay = sceneOverlayFor(
          scenes,
          frameState.sceneId,
          visibleFloorIds,
          ~marketing=marketingOverlay,
        )
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
        let etaStr = frameIndex > 0 ? EtaSupport.formatEtaMs(etaMs) : "Estimating..."
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
