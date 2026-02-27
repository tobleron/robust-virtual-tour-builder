open Types

module StyleCatalog = TeaserStyleCatalog
module RenderRegistry = TeaserRendererRegistry
module OfflineCfrRenderer = TeaserOfflineCfrRenderer

let teaserEtaToastId = "sidebar-teaser-progress"

type teaserProgressMetrics = TeaserLogicHelpers.teaserProgressMetrics

let parseTeaserProgressMetrics = (msg: string): teaserProgressMetrics => {
  TeaserLogicHelpers.parseTeaserProgressMetrics(msg)
}

let signalIsAborted = signal =>
  TeaserLogicHelpers.signalIsAborted(signal)

let startHeadlessTeaserWithStyle = async (
  ~finalizeTeaser,
  format: string,
  ~styleId: option<string>,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
  ~onCancel: option<unit => unit>=?,
) => {
  let state = getState()
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)

  if state.isLinking {
    Logger.warn(~module_="TeaserLogic", ~message="TEASER_BLOCKED_BY_LINKING", ())
  } else if Array.length(activeScenes) == 0 {
    ()
  } else if signalIsAborted(signal) {
    ()
  } else {
    let validationResult = ProjectConnectivity.validateProjectForGeneration(activeScenes)
    switch validationResult {
    | Error({message}) =>
      NotificationManager.dispatch({
        id: "",
        importance: Error,
        context: Operation("teaser"),
        message: "Export blocked: " ++ message,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
      ()
    | Ok() => {
        let selectedStyle =
          styleId
          ->Option.map(raw => StyleCatalog.fromString(raw))
          ->Option.getOr(StyleCatalog.defaultStyle)
        if !StyleCatalog.isAvailable(selectedStyle) {
          NotificationManager.dispatch({
            id: "",
            importance: Warning,
            context: Operation("teaser"),
            message: StyleCatalog.label(selectedStyle) ++ " style unavailable.",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Warning),
            dismissible: true,
            createdAt: Date.now(),
          })
          ()
        } else {
          let canCancel = switch onCancel {
          | Some(_) => true
          | None => false
          }
          let opId = OperationLifecycle.start(
            ~type_=OperationLifecycle.Teaser,
            ~scope=Ambient,
            ~phase="Preparing",
            ~cancellable=canCancel,
            ~visibleAfterMs=250,
            ~meta=Logger.castToJson({
              "format": format,
              "style": StyleCatalog.toString(selectedStyle),
              "sceneCount": Belt.Array.length(activeScenes),
            }),
            (),
          )
          onCancel->Option.forEach(cb => OperationLifecycle.registerCancel(opId, cb))

          let teaserStartedAtMs = Date.now()
          let lastEtaToastAtMs = ref(0.0)
          let lastPctSample = ref(0.0)
          let lastSampleAtMs = ref(teaserStartedAtMs)
          let emaProgressPerSecond = ref(0.0)
          let knownTotalFrames = ref(0)
          let lastRenderedFrameSample = ref(0)
          let lastFrameSampleAtMs = ref(teaserStartedAtMs)
          let emaSecondsPerFrame = ref(0.0)
          let frameSampleCount = ref(0)
          let stableEtaSeconds = ref(0.0)
          let etaReady = ref(false)

          EtaSupport.dismissEtaToast(teaserEtaToastId)
          EtaSupport.dispatchCalculatingEtaToast(
            ~id=teaserEtaToastId,
            ~contextOperation="eta_teaser",
            ~prefix="Generating teaser",
            ~details=Some("Preparing deterministic timeline"),
            (),
          )

          dispatch(Actions.SetIsTeasing(true))
          ProgressBar.updateProgressBar(
            0.0,
            "Calculating teaser path...",
            ~visible=true,
            ~title="Teaser",
            (),
          )

          try {
            OperationLifecycle.progress(
              opId,
              5.0,
              ~message="Building simulation motion manifest|Preparing deterministic timeline",
              ~phase="Preparing",
              (),
            )
            ProgressBar.updateProgressBar(
              5.0,
              "Building " ++
              StyleCatalog.label(
                selectedStyle,
              ) ++ " motion manifest|Preparing deterministic timeline",
              ~visible=true,
              ~title="Teaser",
              (),
            )
            switch RenderRegistry.buildManifestForStyle(
              state,
              ~style=selectedStyle,
              ~skipAutoForward=Constants.Teaser.HeadlessMotion.skipAutoForward,
              ~includeIntroPan=Constants.Teaser.HeadlessMotion.includeIntroPan,
            ) {
            | Error(reason) =>
              if OperationLifecycle.isActive(opId) {
                OperationLifecycle.fail(opId, reason)
              }
              EtaSupport.dismissEtaToast(teaserEtaToastId)
              dispatch(Actions.SetIsTeasing(false))
              ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
            | Ok(manifest) =>
              let success = await OfflineCfrRenderer.renderWebMDeterministic(
                manifest,
                true,
                ~getState,
                ~dispatch,
                ~signal?,
                ~onProgress=(pct, msg, phaseName) => {
                  OperationLifecycle.progress(opId, pct, ~message=msg, ~phase=phaseName, ())
                  ProgressBar.updateProgressBar(pct, msg, ~visible=true, ~title="Teaser", ())

                  if pct > 0.0 && pct < 100.0 {
                    let now = Date.now()
                    let parsed = parseTeaserProgressMetrics(msg)

                    switch (parsed.renderedFrame, parsed.totalFrames) {
                    | (Some(done), Some(total)) =>
                      knownTotalFrames := total
                      if done > lastRenderedFrameSample.contents {
                        let deltaFrames = done - lastRenderedFrameSample.contents
                        let deltaSeconds = (now -. lastFrameSampleAtMs.contents) /. 1000.0
                        if deltaFrames > 0 && deltaSeconds > 0.2 {
                          let instSecondsPerFrame = deltaSeconds /. Belt.Int.toFloat(deltaFrames)
                          if emaSecondsPerFrame.contents <= 0.0 {
                            emaSecondsPerFrame := instSecondsPerFrame
                          } else {
                            emaSecondsPerFrame :=
                              0.74 *. emaSecondsPerFrame.contents +. 0.26 *. instSecondsPerFrame
                          }
                          frameSampleCount := frameSampleCount.contents + 1
                        }
                        lastRenderedFrameSample := done
                        lastFrameSampleAtMs := now
                      }
                    | _ => ()
                    }

                    let deltaPct = pct -. lastPctSample.contents
                    let deltaSec = (now -. lastSampleAtMs.contents) /. 1000.0
                    if deltaPct > 0.0 && deltaSec > 0.3 {
                      let instRate = deltaPct /. deltaSec
                      if emaProgressPerSecond.contents <= 0.0 {
                        emaProgressPerSecond := instRate
                      } else {
                        emaProgressPerSecond :=
                          0.8 *. emaProgressPerSecond.contents +. 0.2 *. instRate
                      }
                      lastPctSample := pct
                      lastSampleAtMs := now
                    }

                    let elapsedSec = (now -. teaserStartedAtMs) /. 1000.0
                    if (
                      !etaReady.contents &&
                      elapsedSec >= 8.0 &&
                      (frameSampleCount.contents >= 3 ||
                        (pct >= 15.0 && emaProgressPerSecond.contents > 0.0))
                    ) {
                      etaReady := true
                    }

                    let shouldUpdateToast = now -. lastEtaToastAtMs.contents >= 1200.0
                    if shouldUpdateToast {
                      let remainingFrames = if (
                        knownTotalFrames.contents > lastRenderedFrameSample.contents
                      ) {
                        knownTotalFrames.contents - lastRenderedFrameSample.contents
                      } else {
                        0
                      }
                      let etaByFrameRate = if (
                        emaSecondsPerFrame.contents > 0.0 && remainingFrames > 0
                      ) {
                        Some(emaSecondsPerFrame.contents *. Belt.Int.toFloat(remainingFrames))
                      } else {
                        None
                      }
                      let etaByProgressSlope = if emaProgressPerSecond.contents > 0.0 {
                        Some((100.0 -. pct) /. emaProgressPerSecond.contents)
                      } else {
                        None
                      }
                      let etaByGlobalAverage = if pct >= 1.0 {
                        Some(elapsedSec /. pct *. (100.0 -. pct))
                      } else {
                        None
                      }

                      let etaFromRenderer =
                        parsed.etaSecondsFromMessage->Option.map(Belt.Int.toFloat)
                      let blendedEta = EtaSupport.combineEtaCandidates(
                        ~a=etaByFrameRate,
                        ~b=etaByProgressSlope,
                        ~c=etaByGlobalAverage,
                        ~d=?etaFromRenderer,
                      )->Option.map(raw =>
                        if phaseName == "Encoding WebM" {
                          raw *. 1.06
                        } else {
                          raw
                        }
                      )

                      let etaSeconds = switch blendedEta {
                      | Some(candidate) if etaReady.contents =>
                        let smoothed = if stableEtaSeconds.contents <= 0.0 {
                          candidate
                        } else {
                          let raw = 0.78 *. stableEtaSeconds.contents +. 0.22 *. candidate
                          let maxRise = stableEtaSeconds.contents +. 20.0
                          let maxDrop = stableEtaSeconds.contents -. 12.0
                          EtaSupport.clampFloat(
                            ~value=raw,
                            ~minValue=Math.max(1.0, maxDrop),
                            ~maxValue=maxRise,
                          )
                        }
                        stableEtaSeconds := smoothed
                        Belt.Float.toInt(smoothed)
                      | _ => 0
                      }

                      lastEtaToastAtMs := now
                      if etaReady.contents {
                        EtaSupport.dispatchEtaToast(
                          ~id=teaserEtaToastId,
                          ~contextOperation="eta_teaser",
                          ~prefix="Generating teaser",
                          ~etaSeconds,
                          ~details=Some(phaseName ++ " • " ++ msg),
                          ~createdAt=now,
                          (),
                        )
                      } else {
                        EtaSupport.dispatchCalculatingEtaToast(
                          ~id=teaserEtaToastId,
                          ~contextOperation="eta_teaser",
                          ~prefix="Generating teaser",
                          ~details=Some(phaseName ++ " • " ++ msg),
                          ~createdAt=now,
                          (),
                        )
                      }
                    }
                  }
                },
              )

              if success {
                OperationLifecycle.progress(
                  opId,
                  99.0,
                  ~message="Finalizing teaser package|Almost done",
                  ~phase="Finalizing",
                  (),
                )
                ProgressBar.updateProgressBar(
                  99.0,
                  "Finalizing teaser package|Almost done",
                  ~visible=true,
                  ~title="Teaser",
                  (),
                )

                let safeName =
                  String.replaceRegExp(state.tourName, /[^a-z0-9]/gi, "_")->String.toLowerCase
                await finalizeTeaser(
                  format,
                  "Teaser_" ++ StyleCatalog.toString(selectedStyle) ++ "_" ++ safeName,
                )

                if OperationLifecycle.isActive(opId) {
                  OperationLifecycle.complete(opId, ~result="Teaser ready", ())
                }
              } else if OperationLifecycle.isActive(opId) {
                OperationLifecycle.fail(opId, "Rendering failed")
              }
              EtaSupport.dismissEtaToast(teaserEtaToastId)
              dispatch(Actions.SetIsTeasing(false))
              ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
            }
          } catch {
          | exn =>
            EtaSupport.dismissEtaToast(teaserEtaToastId)
            dispatch(Actions.SetIsTeasing(false))
            ProgressBar.updateProgressBar(0.0, "", ~visible=false, ~title="", ())
            TeaserRecorder.Recorder.stopRecording()

            let (msg, _) = Logger.getErrorDetails(exn)
            if String.includes(msg, "AbortError") || signalIsAborted(signal) {
              if OperationLifecycle.isActive(opId) {
                OperationLifecycle.cancel(opId)
              }
              NotificationManager.dispatch({
                id: "",
                importance: Info,
                context: Operation("teaser"),
                message: "Teaser generation cancelled",
                details: None,
                action: None,
                duration: NotificationTypes.defaultTimeoutMs(Info),
                dismissible: true,
                createdAt: Date.now(),
              })
            } else {
              Logger.error(
                ~module_="TeaserLogic",
                ~message="TEASER_FAILED",
                ~data=Some(Logger.castToJson({"error": msg})),
                (),
              )
              if OperationLifecycle.isActive(opId) {
                OperationLifecycle.fail(opId, "Teaser generation failed: " ++ msg)
              }
            }
          }
        }
      }
    }
  }
}
