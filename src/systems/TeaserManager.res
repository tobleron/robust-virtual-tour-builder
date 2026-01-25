/* src/systems/TeaserManager.res */

open ReBindings
open Types
open EventBus
module Recorder = TeaserRecorder
module Server = ServerTeaser
module Playback = TeaserPlayback
module State = TeaserState

/* Helper to wait - needed for local logic if any, 
   but we can import from Playback or just redefine if simple. 
   Actually Playback.wait is not public? I made it public (let wait = ...). */
let wait = Playback.wait

/* Bindings for Finalization */
let finalizeTeaser = async (format: string, baseName: string) => {
  let chunks = Recorder.getRecordedBlobs()
  if Belt.Array.length(chunks) > 0 {
    let blob = Blob.newBlob(chunks, {"type": "video/webm"})

    if format == "webm" {
      DownloadSystem.saveBlob(blob, baseName ++ ".webm")
    } else if format == "mp4" {
      let transcodeResult = await VideoEncoder.transcodeWebMToMP4(
        blob,
        baseName,
        Some((_pct, _msg) => ()),
      )
      switch transcodeResult {
      | Ok() => EventBus.dispatch(ShowNotification("Video transcoded successfully", #Success))
      | Error(msg) => {
          Logger.error(
            ~module_="TeaserManager",
            ~message="TRANSCODE_FAILED",
            ~data=Some({"error": msg}),
            (),
          )
          EventBus.dispatch(ShowNotification("Video transcoding failed: " ++ msg, #Error))
        }
      }
    }
  }
}

let startCinematicTeaser = async (includeLogo: bool, format: string, skipAutoForward: bool) => {
  let logoState = await Recorder.loadLogo()

  Logger.startOperation(
    ~module_="TeaserManager",
    ~operation="GENERATE_CINEMATIC",
    ~data=Some({"format": format}),
    (),
  )

  let startTime = Date.now()
  Recorder.startAnimationLoop(includeLogo, logoState)

  let started = Recorder.startRecording()
  if started {
    // Start AutoPilot
    let state = GlobalStateBridge.getState()
    GlobalStateBridge.dispatch(StartAutoPilot(state.currentJourneyId, skipAutoForward))

    let rec checkLoop = async () => {
      await wait(1000)
      if GlobalStateBridge.getState().simulation.status == Running {
        await checkLoop()
      }
    }
    await checkLoop()

    await wait(500)

    Recorder.stopRecording()

    let tourName = GlobalStateBridge.getState().tourName
    let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
    let baseName = "Teaser_Cinematic_" ++ safeName

    Logger.endOperation(
      ~module_="TeaserManager",
      ~operation="GENERATE_CINEMATIC",
      ~data=Some({"durationMs": Date.now() -. startTime}),
      (),
    )

    await finalizeTeaser(format, baseName)
  }
}

/* Expose to Window */
let _ = %raw(`
  (function() {
    if (typeof window !== 'undefined') {
      window.startCinematicTeaser = startCinematicTeaser;
    }
  })()
`)

/* Main Auto Teaser Flow */
let startAutoTeaser = async (
  style: string,
  includeLogo: bool,
  format: string,
  skipAutoForward: bool,
) => {
  let scenes = GlobalStateBridge.getState().scenes
  if Belt.Array.length(scenes) == 0 {
    Logger.error(~module_="TeaserManager", ~message="NO_SCENES_TO_FILM", ())
  } else if style == "cinematic" && format == "mp4" {
    /* Server Side Generation */
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
    ->Promise.then(teaserResult => {
      switch teaserResult {
      | Ok(blob) => {
          let safeName = String.replaceRegExp(state.tourName, /[^a-z0-9]/gi, "_")
          let filename = "Cinematic_" ++ safeName ++ ".mp4"
          DownloadSystem.saveBlob(blob, filename)

          GlobalStateBridge.dispatch(SetIsTeasing(false))
          ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
        }
      | Error(msg) => {
          GlobalStateBridge.dispatch(SetIsTeasing(false))
          ProgressBar.updateProgressBar(
            0.0,
            "Generation Failed",
            ~visible=false,
            ~title="Error",
            (),
          )
          EventBus.dispatch(ShowNotification("Server Generation Failed: " ++ msg, #Error))
        }
      }
      Promise.resolve()
    })
    ->Promise.catch(err => {
      let (msg, _stack) = Logger.getErrorDetails(err)
      GlobalStateBridge.dispatch(SetIsTeasing(false))
      ProgressBar.updateProgressBar(0.0, "Generation Failed", ~visible=false, ~title="Error", ())
      EventBus.dispatch(ShowNotification("Server Generation Failed: " ++ msg, #Error))
      Promise.resolve()
    })
    ->ignore

    ()
  } else {
    /* Client Side Flow */
    let config = State.getConfigForStyle(style)

    let logoState = await Recorder.loadLogo()

    Logger.startOperation(
      ~module_="TeaserManager",
      ~operation="GENERATE",
      ~data=Some({"style": style, "sceneCount": Belt.Array.length(scenes)}),
      (),
    )

    let pathStartTime = Date.now()
    let pathResult = await TeaserPathfinder.getWalkPath(scenes, skipAutoForward)

    switch pathResult {
    | Error(msg) =>
      EventBus.dispatch(ShowNotification("Failed to generate path: " ++ msg, #Error))
      Logger.error(~module_="TeaserManager", ~message="PATH_FAILED", ~data=Some({"error": msg}), ())
    | Ok(pathSteps) => {
        Logger.info(
          ~module_="TeaserManager",
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
            | Some(firstStep) => await Playback.prepareFirstScene(firstStep, style, config)
            | None => ()
            }

            /* 5. Execute Path */
            let len = Belt.Array.length(pathSteps)

            let rec runSteps = async (i: int) => {
              if i < len {
                switch Belt.Array.get(pathSteps, i) {
                | Some(step) => {
                    await Playback.recordShot(i, step, style, config)

                    if i < len - 1 {
                      switch Belt.Array.get(pathSteps, i + 1) {
                      | Some(nextStep) =>
                        await Playback.transitionToNextShot(i, nextStep, style, config)
                      | None => ()
                      }
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
            let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
            let baseName = "Teaser_" ++ style ++ "_" ++ safeName

            Logger.endOperation(
              ~module_="TeaserManager",
              ~operation="GENERATE",
              ~data=Some({
                "style": style,
                "durationMs": Date.now() -. pathStartTime,
                "sceneCount": len,
              }),
              (),
            )

            await finalizeTeaser(format, baseName)
          } catch {
          | exn => {
              let (msg, stack) = Logger.getErrorDetails(exn)
              Logger.error(
                ~module_="TeaserManager",
                ~message="GENERATE_FAILED",
                ~data={"error": msg, "stack": stack},
                (),
              )
              Recorder.stopRecording()
            }
          }
        }
      }
    }
  }
}
