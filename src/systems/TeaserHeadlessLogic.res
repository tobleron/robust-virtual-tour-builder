open Types

module StyleCatalog = TeaserStyleCatalog
module RenderRegistry = TeaserRendererRegistry
module OfflineCfrRenderer = TeaserOfflineCfrRenderer

let teaserEtaToastId = "sidebar-teaser-progress"

type teaserProgressMetrics = TeaserLogicHelpers.teaserProgressMetrics

let parseTeaserProgressMetrics = (msg: string): teaserProgressMetrics => {
  TeaserLogicHelpers.parseTeaserProgressMetrics(msg)
}

let signalIsAborted = signal => TeaserLogicHelpers.signalIsAborted(signal)

let startHeadlessTeaserWithStyle = async (
  ~finalizeTeaser,
  format: string,
  ~styleId: option<string>,
  ~panSpeedId: option<string>,
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
        let selectedPanSpeed = switch selectedStyle {
        | Cinematic => TeaserStyleConfig.resolvePanSpeedOption(panSpeedId)
        | _ => TeaserStyleConfig.defaultPanSpeed
        }
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
              "panSpeedId": selectedPanSpeed.id,
              "panSpeedDegPerSec": selectedPanSpeed.speedDegPerSec,
              "sceneCount": Belt.Array.length(activeScenes),
            }),
            (),
          )
          onCancel->Option.forEach(cb => OperationLifecycle.registerCancel(opId, cb))

          let teaserStartedAtMs = Date.now()
          let etaState: TeaserHeadlessLogicSupport.etaState = {
            teaserStartedAtMs,
            lastEtaToastAtMs: ref(0.0),
            lastPctSample: ref(0.0),
            lastSampleAtMs: ref(teaserStartedAtMs),
            emaProgressPerSecond: ref(0.0),
            knownTotalFrames: ref(0),
            lastRenderedFrameSample: ref(0),
            lastFrameSampleAtMs: ref(teaserStartedAtMs),
            emaSecondsPerFrame: ref(0.0),
            frameSampleCount: ref(0),
            stableEtaSeconds: ref(0.0),
            etaReady: ref(false),
          }

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
              let calibratedManifest = switch selectedStyle {
              | Cinematic => TeaserStyleConfig.applyPanSpeedOption(manifest, selectedPanSpeed)
              | _ => manifest
              }
              let success = await OfflineCfrRenderer.renderWebMDeterministic(
                calibratedManifest,
                true,
                ~getState,
                ~dispatch,
                ~signal?,
                ~onProgress=(pct, msg, phaseName) => {
                  OperationLifecycle.progress(opId, pct, ~message=msg, ~phase=phaseName, ())
                  ProgressBar.updateProgressBar(pct, msg, ~visible=true, ~title="Teaser", ())
                  TeaserHeadlessLogicSupport.handleProgress(
                    ~teaserEtaToastId,
                    ~phaseName,
                    ~msg,
                    ~pct,
                    ~parsed=parseTeaserProgressMetrics(msg),
                    ~etaState,
                  )
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
            TeaserHeadlessLogicSupport.handleFailure(
              ~teaserEtaToastId,
              ~dispatch,
              ~opId,
              ~signal,
              exn,
            )
          }
        }
      }
    }
  }
}
