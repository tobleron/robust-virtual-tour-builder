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

let animatePan = async (fromYaw, toYaw, pitch, duration) => {
  let start = Date.now()
  let rec loop = async () => {
    let p = (Date.now() -. start) /. duration
    if p < 1.0 {
      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, fromYaw +. (toYaw -. fromYaw) *. p, false)
        Viewer.setPitch(v, pitch, false)
      })
      await wait(16)
      await loop()
    } else {
      ViewerSystem.getActiveViewer()
      ->Nullable.toOption
      ->Option.forEach(v => {
        Viewer.setYaw(v, toYaw, false)
        Viewer.setPitch(v, pitch, false)
      })
    }
  }
  await loop()
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
