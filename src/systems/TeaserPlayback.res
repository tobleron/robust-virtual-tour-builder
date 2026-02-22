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
          await wait(200)
          true
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
  let scenes = getState().scenes
  switch Belt.Array.get(scenes, step.idx) {
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
  let scenes = getState().scenes
  switch Belt.Array.get(scenes, nextStep.idx) {
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

type manifestFrameState = {
  sceneId: string,
  pose: viewFrame,
  fadeOpacity: float,
}

type shotTiming = {
  waitMs: float,
  motionMs: float,
  blinkMs: float,
  transitionMs: float,
  totalMs: float,
}

let clamp01 = (v: float): float =>
  if v < 0.0 {
    0.0
  } else if v > 1.0 {
    1.0
  } else {
    v
  }

let getShotMotionDuration = (shot: motionShot): float => {
  switch shot.pathData {
  | Some(pd) => pd.panDuration
  | None =>
    shot.animationSegments->Belt.Array.reduce(0.0, (acc, seg) =>
      acc +. Belt.Int.toFloat(seg.durationMs)
    )
  }
}

let getShotTiming = (shot: motionShot): shotTiming => {
  let waitMs = Belt.Int.toFloat(shot.waitBeforePanMs)
  let motionMs = getShotMotionDuration(shot)
  let blinkMs = Belt.Int.toFloat(shot.blinkAfterPanMs)
  let transitionMs =
    shot.transitionOut->Option.map(t => Belt.Int.toFloat(t.durationMs))->Option.getOr(0.0)
  {
    waitMs,
    motionMs,
    blinkMs,
    transitionMs,
    totalMs: waitMs +. motionMs +. blinkMs +. transitionMs,
  }
}

let getLastSegmentPose = (shot: motionShot): viewFrame => {
  switch Belt.Array.get(shot.animationSegments, Belt.Array.length(shot.animationSegments) - 1) {
  | Some(seg) => {yaw: seg.endYaw, pitch: seg.endPitch, hfov: seg.endHfov}
  | None => shot.arrivalPose
  }
}

let getShotTargetPose = (shot: motionShot): viewFrame => {
  switch shot.pathData {
  | Some(pd) => {
      yaw: pd.targetYawForPan,
      pitch: pd.targetPitchForPan,
      hfov: ViewerSystem.getCorrectHfov(),
    }
  | None => getLastSegmentPose(shot)
  }
}

let interpolateSegments = (shot: motionShot, localMotionMs: float): viewFrame => {
  let rec walk = (idx: int, elapsedMs: float, lastPose: viewFrame): viewFrame => {
    if idx >= Belt.Array.length(shot.animationSegments) {
      lastPose
    } else {
      switch Belt.Array.get(shot.animationSegments, idx) {
      | None => lastPose
      | Some(seg) =>
        let segDuration = Belt.Int.toFloat(seg.durationMs)
        let endPose: viewFrame = {yaw: seg.endYaw, pitch: seg.endPitch, hfov: seg.endHfov}
        if segDuration <= 0.0 {
          walk(idx + 1, elapsedMs, endPose)
        } else if localMotionMs <= elapsedMs +. segDuration {
          let p = clamp01((localMotionMs -. elapsedMs) /. segDuration)
          {
            yaw: seg.startYaw +. (seg.endYaw -. seg.startYaw) *. p,
            pitch: seg.startPitch +. (seg.endPitch -. seg.startPitch) *. p,
            hfov: seg.startHfov +. (seg.endHfov -. seg.startHfov) *. p,
          }
        } else {
          walk(idx + 1, elapsedMs +. segDuration, endPose)
        }
      }
    }
  }

  walk(0, 0.0, shot.arrivalPose)
}

let resolveShotPoseAt = (shot: motionShot, localMs: float): viewFrame => {
  let timing = getShotTiming(shot)
  if localMs <= timing.waitMs {
    shot.arrivalPose
  } else if localMs <= timing.waitMs +. timing.motionMs {
    let motionElapsed = localMs -. timing.waitMs
    switch shot.pathData {
    | Some(pd) if pd.panDuration > 0.0 =>
      let linear = clamp01(motionElapsed /. pd.panDuration)
      let eased = Easing.trapezoidal(linear, 0.12)
      let (pitch, yaw) = NavigationLogic.calculateCameraPosition(~progress=eased, ~pathData=pd)
      {yaw, pitch, hfov: ViewerSystem.getCorrectHfov()}
    | _ => interpolateSegments(shot, motionElapsed)
    }
  } else {
    getShotTargetPose(shot)
  }
}

let getManifestStateAt = (manifest: motionManifest, timeMs: float): manifestFrameState => {
  let shotCount = Belt.Array.length(manifest.shots)
  if shotCount == 0 {
    {
      sceneId: "",
      pose: {yaw: 0.0, pitch: 0.0, hfov: ViewerSystem.getCorrectHfov()},
      fadeOpacity: 0.0,
    }
  } else {
    let elapsedMs = ref(0.0)
    let result = ref(None)

    for idx in 0 to shotCount - 1 {
      if result.contents->Option.isNone {
        switch Belt.Array.get(manifest.shots, idx) {
        | None => ()
        | Some(shot) =>
          let timing = getShotTiming(shot)
          let contentEnd = elapsedMs.contents +. timing.waitMs +. timing.motionMs +. timing.blinkMs
          if timeMs < contentEnd {
            let localMs = timeMs -. elapsedMs.contents
            result :=
              Some({
                sceneId: shot.sceneId,
                pose: resolveShotPoseAt(shot, localMs),
                fadeOpacity: 0.0,
              })
          } else {
            let hasNext = idx + 1 < shotCount
            if hasNext && timing.transitionMs > 0.0 {
              let transitionStart = contentEnd
              let transitionEnd = transitionStart +. timing.transitionMs
              if timeMs < transitionEnd {
                let nextShot = manifest.shots[idx + 1]->Option.getOr(shot)
                let p = clamp01((timeMs -. transitionStart) /. timing.transitionMs)
                result :=
                  Some({
                    sceneId: nextShot.sceneId,
                    pose: nextShot.arrivalPose,
                    fadeOpacity: 1.0 -. p,
                  })
              } else {
                elapsedMs := transitionEnd
              }
            } else {
              elapsedMs := contentEnd
            }
          }
        }
      }
    }

    switch result.contents {
    | Some(value) => value
    | None =>
      let lastShot = manifest.shots[shotCount - 1]->Option.getOrThrow
      {
        sceneId: lastShot.sceneId,
        pose: getShotTargetPose(lastShot),
        fadeOpacity: 0.0,
      }
    }
  }
}

let playManifest = async (
  manifest: Types.motionManifest,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let shotCount = Belt.Array.length(manifest.shots)
  if shotCount == 0 {
    ()
  } else {
    let scenes = getState().scenes
    let frameRate = if manifest.fps > 0 {
      manifest.fps
    } else {
      Constants.Teaser.frameRate
    }
    let frameStepMs = 1000.0 /. Belt.Int.toFloat(frameRate)
    let frameStepIntMs = Math.Int.max(1, Belt.Float.toInt(frameStepMs))
    let totalDurationMs = Manifest.calculateTotalManifestDuration(manifest)
    let totalFrames = Math.Int.max(1, Belt.Float.toInt(totalDurationMs /. frameStepMs))
    let currentSceneId = ref("")

    for frameIndex in 0 to totalFrames {
      let t = Belt.Int.toFloat(frameIndex) *. frameStepMs
      let frameTimeMs = if t > totalDurationMs {
        totalDurationMs
      } else {
        t
      }
      let frameState = getManifestStateAt(manifest, frameTimeMs)

      if frameState.sceneId != "" && frameState.sceneId != currentSceneId.contents {
        if currentSceneId.contents != "" {
          let internalState = TeaserRecorder.Recorder.internalState
          internalState.contents.ghostCanvas->Option.forEach(g =>
            internalState := {...internalState.contents, snapshotCanvas: Some(g)}
          )
          TeaserRecorder.Recorder.setFadeOpacity(1.0)
        }

        let sceneIndex =
          scenes->Belt.Array.getIndexBy(s => s.id == frameState.sceneId)->Option.getOr(-1)
        if sceneIndex >= 0 {
          dispatch(
            Actions.SetActiveScene(sceneIndex, frameState.pose.yaw, frameState.pose.pitch, None),
          )
          await wait(250)
          let _ = await waitForViewerReady(frameState.sceneId)
        }
        currentSceneId := frameState.sceneId
      }

      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, frameState.pose.yaw, false)
        Viewer.setPitch(v, frameState.pose.pitch, false)
        Viewer.setHfov(v, frameState.pose.hfov, false)
      })
      TeaserRecorder.Recorder.setFadeOpacity(frameState.fadeOpacity)
      await wait(frameStepIntMs)
    }

    TeaserRecorder.Recorder.setFadeOpacity(0.0)
  }
}
