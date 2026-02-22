open ReBindings
open Types
external identity: 'a => 'b = "%identity"

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

module Pathfinder = TeaserPathfinder
module State = TeaserStyleConfig

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

let animatePose = async (startPose: Types.viewFrame, endPose: Types.viewFrame, durationMs: float) => {
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

let playManifest = async (
  manifest: Types.motionManifest,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let scenes = getState().scenes
  for i in 0 to Belt.Array.length(manifest.shots) - 1 {
    let shot = manifest.shots[i]->Option.getOrThrow

    // 1. Scene navigation
    let sceneIndex = scenes->Belt.Array.getIndexBy(s => s.id == shot.sceneId)->Option.getOr(0)
    let ny = shot.arrivalPose.yaw
    let np = shot.arrivalPose.pitch
    let nh = shot.arrivalPose.hfov

    // If not first shot, we might need to handle ghost canvas for crossfade
    if i > 0 {
      let internalState = TeaserRecorder.Recorder.internalState
      internalState.contents.ghostCanvas->Option.forEach(g =>
        internalState := {...internalState.contents, snapshotCanvas: Some(g)}
      )
      TeaserRecorder.Recorder.setFadeOpacity(1.0)
      await wait(50)
      TeaserRecorder.Recorder.pause()
    }

    dispatch(Actions.SetActiveScene(sceneIndex, ny, np, None))
    await wait(500)
    let _ = await waitForViewerReady(shot.sceneId)

    ViewerSystem.getActiveViewer()
    ->Nullable.toOption
    ->Option.forEach(v => {
      Viewer.setYaw(v, ny, false)
      Viewer.setPitch(v, np, false)
      Viewer.setHfov(v, nh, false)
    })
    await wait(500)

    if i > 0 {
      TeaserRecorder.Recorder.resume()
      let startD = Date.now()
      let transitionDuration =
        manifest.shots[i - 1]
        ->Option.flatMap(s => s.transitionOut)
        ->Option.map(t => Belt.Int.toFloat(t.durationMs))
        ->Option.getOr(1000.0)

      let rec fade = async () => {
        let p = (Date.now() -. startD) /. transitionDuration
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

    // 2. Play animation segments
    for j in 0 to Belt.Array.length(shot.animationSegments) - 1 {
      let seg = shot.animationSegments[j]->Option.getOrThrow
      await animatePose(
        {yaw: seg.startYaw, pitch: seg.startPitch, hfov: seg.startHfov},
        {yaw: seg.endYaw, pitch: seg.endPitch, hfov: seg.endHfov},
        Belt.Int.toFloat(seg.durationMs),
      )
    }

    // If last shot, we might want to hold or fade to black, but for now we just finish.
  }
}

type manifestFrameState = {
  sceneId: string,
  pose: viewFrame,
  fadeOpacity: float,
}

let getManifestStateAt = (manifest: motionManifest, timeMs: float): manifestFrameState => {
  let rec findShot = (index: int, elapsedMs: float) => {
    if index >= Belt.Array.length(manifest.shots) {
      // Return last state
      let lastShot = manifest.shots[Belt.Array.length(manifest.shots) - 1]->Option.getOrThrow
      let lastSeg = lastShot.animationSegments[Belt.Array.length(lastShot.animationSegments) - 1]->Option.getOrThrow
      {
        sceneId: lastShot.sceneId,
        pose: {yaw: lastSeg.endYaw, pitch: lastSeg.endPitch, hfov: lastSeg.endHfov},
        fadeOpacity: 0.0,
      }
    } else {
      let shot = manifest.shots[index]->Option.getOrThrow
      let prevTransitionDuration = if index > 0 {
        manifest.shots[index - 1]
        ->Option.flatMap(s => s.transitionOut)
        ->Option.map(t => Belt.Int.toFloat(t.durationMs))
        ->Option.getOr(0.0)
      } else {
        0.0
      }

      if timeMs < elapsedMs +. prevTransitionDuration {
        // In fade-in period for this shot
        {
          sceneId: shot.sceneId,
          pose: shot.arrivalPose,
          fadeOpacity: 1.0 -. (timeMs -. elapsedMs) /. prevTransitionDuration,
        }
      } else {
        let afterFadeElapsed = elapsedMs +. prevTransitionDuration
        let rec findSegment = (segIdx: int, segElapsedMs: float) => {
          if segIdx >= Belt.Array.length(shot.animationSegments) {
            // End of shot animation, check if next shot exists
            let shotDuration = segElapsedMs -. afterFadeElapsed
            findShot(index + 1, afterFadeElapsed +. shotDuration)
          } else {
            let seg = shot.animationSegments[segIdx]->Option.getOrThrow
            let segDur = Belt.Int.toFloat(seg.durationMs)
            if timeMs < segElapsedMs +. segDur {
              // In this segment
              let p = (timeMs -. segElapsedMs) /. segDur
              // TODO: Apply easing based on seg.easing
              {
                sceneId: shot.sceneId,
                pose: {
                  yaw: seg.startYaw +. (seg.endYaw -. seg.startYaw) *. p,
                  pitch: seg.startPitch +. (seg.endPitch -. seg.startPitch) *. p,
                  hfov: seg.startHfov +. (seg.endHfov -. seg.startHfov) *. p,
                },
                fadeOpacity: 0.0,
              }
            } else {
              findSegment(segIdx + 1, segElapsedMs +. segDur)
            }
          }
        }
        findSegment(0, afterFadeElapsed)
      }
    }
  }
  findShot(0, 0.0)
}
