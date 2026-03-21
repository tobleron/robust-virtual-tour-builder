open ReBindings
open Types
external identity: 'a => 'b = "%identity"

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

module Pathfinder = TeaserPathfinder
module State = TeaserStyleConfig
module Manifest = TeaserManifest

let wait = (ms: int) =>
  Promise.make((resolve, _) => {
    let _ = setTimeout(() => resolve(), ms)
  })

let waitForAnimationFrame = (): Promise.t<unit> =>
  Promise.make((resolve, _reject) => {
    ignore(ReBindings.Window.requestAnimationFrame(() => resolve()))
  })

let hasRenderableSourceCanvas = (): bool =>
  switch TeaserRecorder.Recorder.resolveSourceCanvas() {
  | Some(canvas) =>
    Dom.getWidth(canvas) > 0 &&
      Dom.getHeight(canvas) > 0 &&
      TeaserRecorderSupport.canvasHasPaintedPixels(canvas)
  | None => false
  }

let waitForRenderableCanvasStability = async (sceneId: string) => {
  let start = Date.now()
  let requiredStableFrames = 6
  let rec check = (stableFrames: int): Promise.t<bool> =>
    if Date.now() -. start > 30000.0 {
      Logger.error(
        ~module_="TeaserLogic",
        ~message="WAIT_FOR_RENDERABLE_CANVAS_TIMEOUT",
        ~data=Some({"targetSceneId": sceneId, "stableFrames": stableFrames}),
        (),
      )
      Promise.resolve(false)
    } else {
      let nextStableFrames = if hasRenderableSourceCanvas() {
        stableFrames + 1
      } else {
        0
      }

      if nextStableFrames >= requiredStableFrames {
        wait(100)->Promise.then(_ => Promise.resolve(true))
      } else {
        waitForAnimationFrame()->Promise.then(_ => check(nextStableFrames))
      }
    }

  await check(0)
}

let waitForViewerReady = async (sceneId: string) => {
  let start = Date.now()
  let rec check = async () => {
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
          await waitForRenderableCanvasStability(sceneId)
        } else {
          await wait(100)
          await check()
        }
      | _ =>
        await wait(100)
        await check()
      }
    }
  }
  await check()
}

let animatePose = async (
  startPose: Types.viewFrame,
  endPose: Types.viewFrame,
  durationMs: float,
) => {
  let start = Date.now()
  let rec loop = async () => {
    let p = (Date.now() -. start) /. durationMs
    if p < 1.0 {
      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, startPose.yaw +. (endPose.yaw -. startPose.yaw) *. p, false)
        Viewer.setPitch(v, startPose.pitch +. (endPose.pitch -. startPose.pitch) *. p, false)
        Viewer.setHfov(v, startPose.hfov +. (endPose.hfov -. startPose.hfov) *. p, false)
      })
      await wait(16)
      await loop()
    } else {
      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, endPose.yaw, false)
        Viewer.setPitch(v, endPose.pitch, false)
        Viewer.setHfov(v, endPose.hfov, false)
      })
    }
  }
  await loop()
}

let animatePan = async (fromYaw, toYaw, pitch, duration) => {
  await animatePose(
    {yaw: fromYaw, pitch, hfov: Constants.globalHfov},
    {yaw: toYaw, pitch, hfov: Constants.globalHfov},
    duration,
  )
}

let prepareFirstScene = async (
  step: Pathfinder.step,
  style,
  config: State.teaserConfig,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let (iy, ip) = if style == "punchy" || style == "cinematic" {
    (step.arrivalView.yaw, step.arrivalView.pitch)
  } else {
    step.transitionTarget
    ->Option.map(t => (t.yaw -. config.cameraPanOffset, t.pitch))
    ->Option.getOr((0.0, 0.0))
  }
  let state = getState()
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch Belt.Array.get(activeScenes, step.idx) {
  | Some(scene) =>
    dispatch(Actions.SetActiveScene(step.idx, iy, ip, None))
    await wait(500)
    let _ = await waitForViewerReady(scene.id)
    ViewerSystem.getActiveViewer()
    ->Nullable.toOption
    ->Option.forEach(v => {
      Viewer.setYaw(v, iy, false)
      Viewer.setPitch(v, ip, false)
    })
    await wait(500)
  | None => ()
  }
}

let recordShot = async (_i, step: Pathfinder.step, style, config: State.teaserConfig) => {
  if style == "punchy" || style == "cinematic" {
    await wait(Belt.Int.fromFloat(config.clipDuration))
  } else {
    switch step.transitionTarget {
    | Some(t) =>
      await animatePan(t.yaw -. config.cameraPanOffset, t.yaw, t.pitch, config.clipDuration)
    | None => await wait(Belt.Int.fromFloat(config.clipDuration))
    }
  }
}

let transitionToNextShot = async (
  _i,
  nextStep: Pathfinder.step,
  style,
  config: State.teaserConfig,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let internalState = TeaserRecorder.Recorder.internalState
  internalState.contents.ghostCanvas->Option.forEach(g =>
    internalState := {...internalState.contents, snapshotCanvas: Some(g)}
  )
  TeaserRecorder.Recorder.setFadeOpacity(1.0)
  await wait(50)
  TeaserRecorder.Recorder.pause()
  let (ny, np) = if style == "punchy" {
    (nextStep.arrivalView.yaw, nextStep.arrivalView.pitch)
  } else {
    nextStep.transitionTarget
    ->Option.map(t => (t.yaw -. config.cameraPanOffset, t.pitch))
    ->Option.getOr((nextStep.arrivalView.yaw, nextStep.arrivalView.pitch))
  }
  let state = getState()
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  switch Belt.Array.get(activeScenes, nextStep.idx) {
  | Some(scene) =>
    dispatch(Actions.SetActiveScene(nextStep.idx, ny, np, None))
    await wait(500)
    let _ = await waitForViewerReady(scene.id)
    ViewerSystem.getActiveViewer()
    ->Nullable.toOption
    ->Option.forEach(v => {
      Viewer.setYaw(v, ny, false)
      Viewer.setPitch(v, np, false)
    })
    await wait(500)
  | None => ()
  }
  TeaserRecorder.Recorder.resume()
  let startD = Date.now()
  let rec fade = async () => {
    let p = (Date.now() -. startD) /. config.transitionDuration
    if p < 1.0 {
      TeaserRecorder.Recorder.setFadeOpacity(1.0 -. p)
      await wait(16)
      await fade()
    } else {
      TeaserRecorder.Recorder.setFadeOpacity(0.0)
    }
  }
  await fade()
}

type manifestFrameState = TeaserPlaybackManifest.manifestFrameState

type shotTiming = TeaserPlaybackManifest.shotTiming

let clamp01 = (v: float): float => {
  TeaserPlaybackManifest.clamp01(v)
}

let getShotMotionDuration = (shot: motionShot): float => {
  TeaserPlaybackManifest.getShotMotionDuration(shot)
}

let getShotTiming = (shot: motionShot): shotTiming => {
  TeaserPlaybackManifest.getShotTiming(shot)
}

let getLastSegmentPose = (shot: motionShot): viewFrame => {
  TeaserPlaybackManifest.getLastSegmentPose(shot)
}

let getShotTargetPose = (shot: motionShot): viewFrame => {
  TeaserPlaybackManifest.getShotTargetPose(shot)
}

let interpolateSegments = (shot: motionShot, localMotionMs: float): viewFrame => {
  TeaserPlaybackManifest.interpolateSegments(shot, localMotionMs)
}

let resolveShotPoseAt = (shot: motionShot, localMs: float): viewFrame => {
  TeaserPlaybackManifest.resolveShotPoseAt(shot, localMs)
}

let getManifestStateAt = (manifest: motionManifest, timeMs: float): manifestFrameState => {
  TeaserPlaybackManifest.getManifestStateAt(manifest, timeMs)
}

let playManifest = async (
  manifest: Types.motionManifest,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  await TeaserPlaybackManifest.playManifest(
    manifest,
    ~getState,
    ~dispatch,
    ~wait,
    ~waitForViewerReady,
  )
}
