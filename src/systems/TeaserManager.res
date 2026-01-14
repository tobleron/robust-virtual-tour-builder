/* src/systems/TeaserManager.res */

open ReBindings
open Types
open EventBus
module Recorder = TeaserRecorder
module Server = ServerTeaser

/* Types */
type teaserConfig = {
  clipDuration: float,
  transitionDuration: float,
  cameraPanOffset: float,
}

/* Constants */
let fastConfig = {
  clipDuration: 2500.0,
  transitionDuration: 1000.0,
  cameraPanOffset: 20.0,
}

let slowConfig = {
  clipDuration: 4000.0,
  transitionDuration: 1500.0,
  cameraPanOffset: 30.0,
}

let punchyConfig = {
  clipDuration: 1800.0,
  transitionDuration: 600.0, // Flash cut basically
  cameraPanOffset: 0.0,
}

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
      switch ReBindings.Viewer.instance->Nullable.toOption {
      | Some(v) =>
        /* In JS logic: check if viewer is loaded and scene matches */
        /* We assume getConfig() handles sceneId check indirectly or we trust flow */
        let _cfg = Viewer.getConfig(v)
        /* Rough check: if we can access config, it's likely initialized */
        /* Real check: if (v.isLoaded() && v.getScene() == sceneId) */
        let isLoaded: bool = Obj.magic(v)["isLoaded"]()
        let currentScene: string = Obj.magic(v)["getScene"]()

        if isLoaded && currentScene == sceneId {
          /* Wait for canvas render - rough heuristic */
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
      switch ReBindings.Viewer.instance->Nullable.toOption {
      | Some(v) =>
        let currentYaw = fromYaw +. (toYaw -. fromYaw) *. p
        Viewer.setYaw(v, currentYaw, false)
        Viewer.setPitch(v, pitch, false)
      | None => ()
      }
      let _ = ReBindings.Window.requestAnimationFrame(() => ())
      /* RAF in async loop is tricky in ReScript without binding returning promise.
       Let's use slight delay or assume loop continues via recursion */
      await wait(16) /* ~60fps */
      await loop()
    } else {
      /* Finalize */
      switch ReBindings.Viewer.instance->Nullable.toOption {
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
  config: teaserConfig,
) => {
  let initialYaw = ref(0.0)
  let initialPitch = ref(0.0)

  if style == "punchy" {
    initialYaw := step.arrivalView.yaw
    initialPitch := step.arrivalView.pitch
  } else if style == "cinematic" {
    /* complex cinematic start logic */
    initialYaw := step.arrivalView.yaw
    initialPitch := step.arrivalView.pitch
  } else {
    /* Dissolve */
    switch step.transitionTarget {
    | Some(t) =>
      initialYaw := t.yaw -. config.cameraPanOffset
      initialPitch := t.pitch
    | None => ()
    }
  }

  /* Set Store */
  /* Store.setActiveScene(step.idx, initialYaw, initialPitch) - binding needed? */
  /* Or direct store mutation via bindings */

  /* Let's assume we trigger scene load via specific action or URL change if needed
   But simpler: accessing scene obj and ensuring viewer loads it */
  let scenes = GlobalStateBridge.getState().scenes
  switch Belt.Array.get(scenes, step.idx) {
  | Some(scene) =>
    /* Trigger load - assuming global function or store action */
    /* For now, let's use Viewer.loadScene if available or Store action */
    /* In JS: store.setActiveScene(index, yaw, pitch) */
    GlobalStateBridge.dispatch(
      SetActiveScene(step.idx, initialYaw.contents, initialPitch.contents, None),
    )

    await wait(500)
    let _ = await waitForViewerReady(scene.id)
    Logger.debug(~module_="Teaser", ~message="SCENE_LOADED", ~data=Some({"sceneName": scene.id}), ())

    /* Force orientation */
    switch ReBindings.Viewer.instance->Nullable.toOption {
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
  config: teaserConfig,
) => {
  /* Update UI omitted for brevity */
  Logger.debug(~module_="Teaser", ~message="RECORD_SHOT_START", ~data=Some({"stepIndex": _i}), ())

  if style == "punchy" {
    await wait(config.clipDuration->Belt.Int.fromFloat)
  } else if style == "cinematic" {
    /* Cinematic path logic - complex, delegate? */
    /* For MVP/Refactor first pass: fallback to simple wait or simple pan */
    await wait(config.clipDuration->Belt.Int.fromFloat)
  } else {
    /* Dissolve Pan */
    switch step.transitionTarget {
    | Some(t) =>
      let startYaw = t.yaw -. config.cameraPanOffset
      await animatePan(startYaw, t.yaw, t.pitch, config.clipDuration)
    | None =>
      /* Just hold if no target (end of tour) */
      await wait(config.clipDuration->Belt.Int.fromFloat)
    }
  }
}

/* TRANSITION */
let transitionToNextShot = async (
  _i: int,
  nextStep: TeaserPathfinder.step,
  style: string,
  _config: teaserConfig,
) => {
  /* 1. Snapshot */
  switch Recorder.getGhostCanvas() {
  | Some(ghost) => Recorder.setSnapshot(ghost)
  | None => ()
  }
  Recorder.setFadeOpacity(1.0)

  await wait(50) /* frame sync */

  /* 2. Pause */
  Recorder.pauseRecording()

  /* 3. Determine Next Orientation */
  let nextYaw = ref(0.0)
  let nextPitch = ref(0.0)

  if style == "punchy" {
    nextYaw := nextStep.arrivalView.yaw
    nextPitch := nextStep.arrivalView.pitch
  } else {
    /* Dissolve uses start position offset */
    /* But wait, we load the scene at the ARRIVAL view or the PAN START view? */
    /* In JS: if dissolve, we load at (transitionTarget.yaw - offset) IF we are going to Pan.
     But here we are ARRIVING at the new scene. */
    /* JS Logic: 
            if (dissolve) {
               nextYaw = nextStep.arrivalView.yaw  // Wait, JS says: nextYaw = nextStep.transitionTarget.yaw - offset ? 
               // Actually JS `transitionToNextShot` logic around line 811 says:
               // "For dissolve... we want to START the shot at (transitionTarget - offset)"
               // So yes.
               if (nextStep.transitionTarget) {
                 nextYaw = nextStep.transitionTarget.yaw - config.cameraPanOffset
               }
            }
 */
    switch nextStep.transitionTarget {
    | Some(t) =>
      /* We need config here */
      nextYaw := t.yaw -. 20.0 /* Hardcoded default for now or pass config */
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
    Logger.debug(~module_="Teaser", ~message="SCENE_LOADED", ~data=Some({"sceneName": scene.id}), ())

    /* Force Orientation */
    switch ReBindings.Viewer.instance->Nullable.toOption {
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
  let dur = 1000.0 /* Default transition duration */
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

/* Bindings for Finalization */
@module("./DownloadSystem.js") @scope("DownloadSystem")
external saveBlob: (TeaserRecorder.blob, string) => unit = "saveBlob"
/* VideoEncoder now used directly from module */

let finalizeTeaser = async (format: string, baseName: string) => {
  let chunks = Recorder.getRecordedBlobs()
  if Belt.Array.length(chunks) > 0 {
    let blob = ReBindings.Blob.newBlob(chunks, {"type": "video/webm"})

    if format == "webm" {
      saveBlob(blob, baseName ++ ".webm")
    } else if format == "mp4" {
      try {
        await VideoEncoder.transcodeWebMToMP4(Obj.magic(blob), baseName, Some((_pct, _msg) => ()))
        /* Success notification? */
      } catch {
      | JsExn(e) => {
          let msg = e->JsExn.message->Option.getOr("Unknown")
          Logger.error(~module_="Teaser", ~message="TRANSCODE_FAILED", ~data=Some({"error": msg}), ())
          saveBlob(blob, baseName ++ ".webm") /* Fallback */
        }
      | _ => {
          Logger.error(~module_="Teaser", ~message="TRANSCODE_FAILED", ~data=Some({"error": "Unknown"}), ())
          saveBlob(blob, baseName ++ ".webm") /* Fallback */
        }
      }
    }
  }
}

let startCinematicTeaser = async (includeLogo: bool, format: string, skipAutoForward: bool) => {
  let logoState = await Recorder.loadLogo()
  
  Logger.startOperation(
    ~module_="Teaser",
    ~operation="GENERATE_CINEMATIC",
    ~data=Some({"format": format}),
    (),
  )
  
  let startTime = Date.now()
  Recorder.startAnimationLoop(includeLogo, logoState)

  let started = Recorder.startRecording()
  if started {
    SimulationSystem.startAutoPilot(Some(skipAutoForward))

    let rec checkLoop = async () => {
      await wait(1000)
      if SimulationSystem.isAutoPilotActive() {
        await checkLoop()
      }
    }
    await checkLoop()

    await wait(500)

    Recorder.stopRecording()

    let tourName = GlobalStateBridge.getState().tourName
    let safeName = Js.String.replaceByRe(/[^a-z0-9]/gi, "_", tourName)->String.toLowerCase
    let baseName = "Teaser_Cinematic_" ++ safeName

    Logger.endOperation(
      ~module_="Teaser",
      ~operation="GENERATE_CINEMATIC",
      ~data=Some({"durationMs": Date.now() -. startTime}),
      (),
    )

    await finalizeTeaser(format, baseName)
  }
}

/* Expose to Window */
let _ = Obj.magic(ReBindings.Window.window)["startCinematicTeaser"] = startCinematicTeaser

/* Main Auto Teaser Flow (Updated for Finalize) */
let startAutoTeaser = async (
  style: string,
  includeLogo: bool,
  format: string,
  skipAutoForward: bool,
) => {
  let scenes = GlobalStateBridge.getState().scenes
  if Belt.Array.length(scenes) == 0 {
    Logger.error(~module_="Teaser", ~message="NO_SCENES_TO_FILM", ())
  } /* Check for Server-Side Cinematic MP4 case */
  else if style == "cinematic" && format == "mp4" {
    GlobalStateBridge.dispatch(SetIsTeasing(true))
    ProgressBar.updateProgressBar(
      0.0,
      "Server Generating...",
      ~visible=true,
      ~title="Uploading",
      (),
    )

    let state = GlobalStateBridge.getState()

    Server.generateServerTeaser(
      state,
      Some(
        (pct, msg) => {
          let phase = if pct < 50 {
            "Uploading"
          } else {
            "Processing"
          }
          ProgressBar.updateProgressBar(Belt.Int.toFloat(pct), msg, ~visible=true, ~title=phase, ())
        },
      ),
    )
    ->Promise.then(blob => {
      let safeName = Js.String.replaceByRe(/[^a-z0-9]/gi, "_", state.tourName)
      let filename = "Cinematic_" ++ safeName ++ ".mp4"
      DownloadSystem.saveBlob(blob, filename)

      GlobalStateBridge.dispatch(SetIsTeasing(false))
      ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      GlobalStateBridge.dispatch(SetIsTeasing(false))
      ProgressBar.updateProgressBar(0.0, "Generation Failed", ~visible=false, ~title="Error", ())
      EventBus.dispatch(ShowNotification("Server Generation Failed", #Error))
      Promise.resolve()
    })
    ->ignore

    ()
  } else {
    /* Client Side Flow */
    let config = switch style {
    | "punchy" => punchyConfig
    | "slow" => slowConfig
    | _ => fastConfig
    }

    let logoState = await Recorder.loadLogo()
    
    Logger.startOperation(
      ~module_="Teaser",
      ~operation="GENERATE",
      ~data=Some({"style": style, "sceneCount": Belt.Array.length(scenes)}),
      (),
    )
    
    let pathStartTime = Date.now()
    let pathSteps = await TeaserPathfinder.getWalkPath(scenes, skipAutoForward)
    Logger.info(
      ~module_="Teaser",
      ~message="PATH_READY",
      ~data=Some({
        "steps": Belt.Array.length(pathSteps),
        "durationMs": Date.now() -. pathStartTime,
      }),
      (),
    )

    Recorder.startAnimationLoop(includeLogo, logoState)
    let started = Recorder.startRecording()

    if started {
      try {
        /* 4. Prepare First */
        switch Belt.Array.get(pathSteps, 0) {
        | Some(firstStep) => await prepareFirstScene(firstStep, style, config)
        | None => ()
        }

        /* 5. Execute Path */
        let len = Belt.Array.length(pathSteps)

        let rec runSteps = async (i: int) => {
          if i < len {
            switch Belt.Array.get(pathSteps, i) {
            | Some(step) =>
              await recordShot(i, step, style, config)

              if i < len - 1 {
                switch Belt.Array.get(pathSteps, i + 1) {
                | Some(nextStep) => await transitionToNextShot(i, nextStep, style, config)
                | None => ()
                }
              }
            | None => ()
            }
            await runSteps(i + 1)
          }
        }

        await runSteps(0)

        Recorder.stopRecording()

        let tourName = GlobalStateBridge.getState().tourName
        let safeName = Js.String.replaceByRe(/[^a-z0-9]/gi, "_", tourName)->String.toLowerCase
        let baseName = "Teaser_" ++ style ++ "_" ++ safeName
        
        Logger.endOperation(
          ~module_="Teaser",
          ~operation="GENERATE",
          ~data=Some({
            "style": style,
            "durationMs": Date.now() -. pathStartTime, // Rough total duration
            "sceneCount": len,
          }),
          (),
        )

        await finalizeTeaser(format, baseName)
      } catch {
      | JsExn(e) => {
          let msg = e->JsExn.message->Option.getOr("Unknown")
          Logger.error(~module_="Teaser", ~message="GENERATE_FAILED", ~data=Some({"error": msg}), ())
          Recorder.stopRecording()
        }
      | _ => {
          Logger.error(~module_="Teaser", ~message="GENERATE_FAILED", ~data=Some({"error": "Unknown"}), ())
          Recorder.stopRecording()
        }
      }
    }
  }
}
