/* src/systems/TeaserPlayback.res */

open ReBindings
open Types

module Recorder = TeaserRecorder
module State = TeaserState

/* Helper to wait */
let wait = (ms: int) => {
  Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => resolve(), ms)
  })
}

/* Viewer Helpers */
let waitForViewerReady = async (sceneId: string) => {
  let checkInterval = 100
  let timeout = 12000
  let start = Date.now()

  let rec check = async () => {
    if Date.now() -. start > timeout->Belt.Int.toFloat {
      false
    } else {
      switch Viewer.instance->Nullable.toOption {
      | Some(v) =>
        let isLoaded = Viewer.isLoaded(v)
        let currentScene = Viewer.getScene(v)

        if isLoaded && currentScene == sceneId {
          await wait(200)
          true
        } else {
          await wait(checkInterval)
          await check()
        }
      | None =>
        await wait(checkInterval)
        await check()
      }
    }
  }
  await check()
}

/* Logic for simple Pan Animation (Dissolve) */
let animatePan = async (fromYaw: float, toYaw: float, pitch: float, duration: float) => {
  let start = Date.now()
  let rec loop = async () => {
    let now = Date.now()
    let p = (now -. start) /. duration

    if p < 1.0 {
      switch Viewer.instance->Nullable.toOption {
      | Some(v) =>
        let currentYaw = fromYaw +. (toYaw -. fromYaw) *. p
        Viewer.setYaw(v, currentYaw, false)
        Viewer.setPitch(v, pitch, false)
      | None => ()
      }
      /* Assuming Window.requestAnimationFrame is bound or we use wait */
      await wait(16)
      await loop()
    } else {
      switch Viewer.instance->Nullable.toOption {
      | Some(v) =>
        Viewer.setYaw(v, toYaw, false)
        Viewer.setPitch(v, pitch, false)
      | None => ()
      }
    }
  }
  await loop()
}

/* PREPARE FIRST SCENE */
let prepareFirstScene = async (
  step: TeaserPathfinder.step,
  style: string,
  config: State.teaserConfig,
) => {
  let initialYaw = ref(0.0)
  let initialPitch = ref(0.0)

  if style == "punchy" {
    initialYaw := step.arrivalView.yaw
    initialPitch := step.arrivalView.pitch
  } else if style == "cinematic" {
    initialYaw := step.arrivalView.yaw
    initialPitch := step.arrivalView.pitch
  } else {
    switch step.transitionTarget {
    | Some(t) =>
      initialYaw := t.yaw -. config.cameraPanOffset
      initialPitch := t.pitch
    | None => ()
    }
  }

  let scenes = GlobalStateBridge.getState().scenes
  switch Belt.Array.get(scenes, step.idx) {
  | Some(scene) =>
    GlobalStateBridge.dispatch(
      SetActiveScene(step.idx, initialYaw.contents, initialPitch.contents, None),
    )

    await wait(500)
    let _ = await waitForViewerReady(scene.id)
    Logger.debug(
      ~module_="TeaserPlayback",
      ~message="SCENE_LOADED",
      ~data=Some({"sceneName": scene.id}),
      (),
    )

    switch Viewer.instance->Nullable.toOption {
    | Some(v) =>
      Viewer.setYaw(v, initialYaw.contents, false)
      Viewer.setPitch(v, initialPitch.contents, false)
    | None => ()
    }

    await wait(500)
  | None => ()
  }
}

/* RECORD SHOT */
let recordShot = async (
  _i: int,
  step: TeaserPathfinder.step,
  style: string,
  config: State.teaserConfig,
) => {
  Logger.debug(
    ~module_="TeaserPlayback",
    ~message="RECORD_SHOT_START",
    ~data=Some({"stepIndex": _i}),
    (),
  )

  if style == "punchy" {
    await wait(config.clipDuration->Belt.Int.fromFloat)
  } else if style == "cinematic" {
    await wait(config.clipDuration->Belt.Int.fromFloat)
  } else {
    switch step.transitionTarget {
    | Some(t) =>
      let startYaw = t.yaw -. config.cameraPanOffset
      await animatePan(startYaw, t.yaw, t.pitch, config.clipDuration)
    | None => await wait(config.clipDuration->Belt.Int.fromFloat)
    }
  }
}

/* TRANSITION */
let transitionToNextShot = async (
  _i: int,
  nextStep: TeaserPathfinder.step,
  style: string,
  config: State.teaserConfig,
) => {
  // Note: Added config usage properly where previously it might have been ignored

  /* 1. Snapshot */
  switch Recorder.getGhostCanvas() {
  | Some(ghost) => Recorder.setSnapshot(ghost)
  | None => ()
  }
  Recorder.setFadeOpacity(1.0)

  await wait(50)

  /* 2. Pause */
  Recorder.pauseRecording()

  /* 3. Determine Next Orientation */
  let nextYaw = ref(0.0)
  let nextPitch = ref(0.0)

  if style == "punchy" {
    nextYaw := nextStep.arrivalView.yaw
    nextPitch := nextStep.arrivalView.pitch
  } else {
    switch nextStep.transitionTarget {
    | Some(t) =>
      nextYaw := t.yaw -. config.cameraPanOffset
      nextPitch := t.pitch
    | None =>
      nextYaw := nextStep.arrivalView.yaw
      nextPitch := nextStep.arrivalView.pitch
    }
  }

  /* 4. Load Scene */
  let scenes = GlobalStateBridge.getState().scenes
  switch Belt.Array.get(scenes, nextStep.idx) {
  | Some(scene) =>
    GlobalStateBridge.dispatch(
      SetActiveScene(nextStep.idx, nextYaw.contents, nextPitch.contents, None),
    )

    await wait(500)
    let _ = await waitForViewerReady(scene.id)
    Logger.debug(
      ~module_="TeaserPlayback",
      ~message="SCENE_LOADED",
      ~data=Some({"sceneName": scene.id}),
      (),
    )

    switch Viewer.instance->Nullable.toOption {
    | Some(v) =>
      Viewer.setYaw(v, nextYaw.contents, false)
      Viewer.setPitch(v, nextPitch.contents, false)
    | None => ()
    }

    await wait(500)
  | None => ()
  }

  /* 5. Resume and Cross Dissolve */
  Recorder.resumeRecording()

  /* Cross Dissolve Animation for Opacity */
  let dur = config.transitionDuration
  let startD = Date.now()
  let rec fade = async () => {
    let now = Date.now()
    let p = (now -. startD) /. dur
    if p < 1.0 {
      Recorder.setFadeOpacity(1.0 -. p)
      await wait(16)
      await fade()
    } else {
      Recorder.setFadeOpacity(0.0)
    }
  }
  await fade()
}
