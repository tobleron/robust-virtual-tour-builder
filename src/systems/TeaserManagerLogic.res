open ReBindings
open Types

module Recorder = TeaserRecorder.Recorder
module Headless = TeaserHeadlessLogic

module Manager = {
  let signalIsAborted = signal => TeaserLogicHelpers.signalIsAborted(signal)

  let finalizeTeaser = async (format, baseName) => {
    let chunks = Recorder.getRecordedBlobs()
    if Array.length(chunks) > 0 {
      let blob = Blob.newBlob(chunks, {"type": "video/webm"})
      if format == "webm" {
        DownloadSystem.saveBlob(blob, baseName ++ ".webm")
      } else {
        let res = await VideoEncoder.transcodeWebMToMP4(blob, baseName, None)
        switch res {
        | Ok(_) => ()
        | Error(_msg) =>
          NotificationManager.dispatch({
            id: "",
            importance: Warning,
            context: Operation("teaser"),
            message: "MP4 encoding failed. Downloading WebM.",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Warning),
            dismissible: true,
            createdAt: Date.now(),
          })
          DownloadSystem.saveBlob(blob, baseName ++ ".webm")
        }
      }
    }
  }

  let startCinematicTeaser = async (
    includeLogo,
    format,
    skipAutoForward,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
  ) => {
    let state = getState()
    let logoState = await Recorder.loadLogo(state.logo)
    Recorder.startAnimationLoop(includeLogo, logoState)
    if Recorder.startRecording() {
      dispatch(Actions.StartAutoPilot(state.navigationState.currentJourneyId, skipAutoForward))
      let rec check = async () => {
        await TeaserPlayback.wait(1000)
        if getState().simulation.status == Running {
          await check()
        }
      }
      await check()
      await TeaserPlayback.wait(500)
      Recorder.stopRecording()
      let safeName =
        String.replaceRegExp(getState().tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
      await finalizeTeaser(format, "Teaser_Cinematic_" ++ safeName)
    }
  }

  let startHeadlessTeaserWithStyle = async (
    format: string,
    ~styleId: option<string>,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onCancel: option<unit => unit>=?,
  ) => {
    await Headless.startHeadlessTeaserWithStyle(
      ~finalizeTeaser,
      format,
      ~styleId,
      ~getState,
      ~dispatch,
      ~signal?,
      ~onCancel?,
    )
  }

  let startHeadlessTeaser = (
    format: string,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onCancel: option<unit => unit>=?,
  ) =>
    startHeadlessTeaserWithStyle(format, ~styleId=None, ~getState, ~dispatch, ~signal?, ~onCancel?)

  let startAutoTeaser = (
    format: string,
    ~getState: unit => Types.state,
    ~dispatch: Actions.action => unit,
    ~signal: option<BrowserBindings.AbortSignal.t>=?,
    ~onCancel: option<unit => unit>=?,
  ) => startHeadlessTeaser(format, ~getState, ~dispatch, ~signal?, ~onCancel?)
}
