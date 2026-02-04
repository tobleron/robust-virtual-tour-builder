/* src/Main.res */
/* --- LEGACY RUNTIME SHIMS (For compatibility with older libraries in ReScript v12) --- */
%%raw(`
  if (typeof globalThis.Caml_option === 'undefined') {
    globalThis.Caml_option = {
      valFromOption: (x) => {
        if (x === null || x === undefined || x.BS_PRIVATE_NESTED_SOME_NONE === undefined) {
          return x;
        }
        let depth = x.BS_PRIVATE_NESTED_SOME_NONE;
        if (depth === 0) {
          return undefined;
        } else {
          return {
            BS_PRIVATE_NESTED_SOME_NONE: depth - 1
          };
        }
      }
    };
  }
`)

open ReBindings

// --- ADDITIONAL BINDINGS ---

module Navigator = {
  @val @scope("navigator") external userAgent: string = "userAgent"
  @val @scope("navigator") external platform: string = "platform"
  @val @scope("navigator") external hardwareConcurrency: int = "hardwareConcurrency"
  @val @scope("navigator") external deviceMemory: float = "deviceMemory"
}

module Screen = {
  @val @scope(("window", "screen")) external width: int = "width"
  @val @scope(("window", "screen")) external height: int = "height"
  @val @scope("window") external devicePixelRatio: float = "devicePixelRatio"
}

module WebGLDebugInfo = {
  type t
  @get external unmaskedRendererWebgl: t => int = "UNMASKED_RENDERER_WEBGL"
  @get external unmaskedVendorWebgl: t => int = "UNMASKED_VENDOR_WEBGL"
}

module WebGL = {
  type t
  @send external getContext: (Dom.element, string) => Nullable.t<t> = "getContext"
  @send external getExtension: (t, string) => Nullable.t<WebGLDebugInfo.t> = "getExtension"
  @send external getParameter: (t, int) => string = "getParameter"
}

module ViewerClickEvent = {
  type detail = {
    pitch: float,
    yaw: float,
    camPitch: float,
    camYaw: float,
    camHfov: float,
  }

  type t
  @get external detail: t => detail = "detail"
  external fromEvent: Dom.event => t = "%identity"
}

@val @scope(("window", "location")) external getHref: unit => string = "toString"

external docToEl: {..} => Dom.element = "%identity"

// --- INITIALIZATION ---

let init = async () => {
  let isInitialized: bool = %raw(`!!window.__VTB_INITIALIZED__`)
  if !isInitialized {
    ignore(%raw(`window.__VTB_INITIALIZED__ = true`))

    try {
      // 1. Logger (Now handles all global error trapping)
      Logger.init()

      Logger.info(~module_="System", ~message="Initializing Tour Builder...", ())
      Logger.info(~module_="Main", ~message="Main Init Started", ())

      // Verify Global Dependencies
      let hasPannellum: bool = %raw("typeof window.pannellum !== 'undefined'")
      if hasPannellum {
        Logger.info(~module_="System", ~message="Pannellum Global Found", ())
        Logger.info(~module_="Main", ~message="Pannellum Found", ())
      } else {
        Logger.error(~module_="System", ~message="Pannellum Global MISSING", ())
      }

      // 2. Global JSON store access (for legacy scripts/console)
      StateInspector.exposeToWindow()

      // 3. Telemetry
      try {
        let canvas = Dom.createElement("canvas")
        let glOpt = WebGL.getContext(canvas, "webgl")

        let (renderer, vendor) = switch glOpt->Nullable.toOption {
        | Some(gl) =>
          let debugInfo = WebGL.getExtension(gl, "WEBGL_debug_renderer_info")
          switch debugInfo->Nullable.toOption {
          | Some(ext) => (
              gl->WebGL.getParameter(WebGLDebugInfo.unmaskedRendererWebgl(ext)),
              gl->WebGL.getParameter(WebGLDebugInfo.unmaskedVendorWebgl(ext)),
            )
          | None => ("unknown", "unknown")
          }
        | None => ("unknown", "unknown")
        }

        Logger.info(
          ~module_="System",
          ~message="Application Startup",
          ~data=Some({
            "userAgent": Navigator.userAgent,
            "platform": Navigator.platform,
            "cores": Navigator.hardwareConcurrency,
            "memory": Navigator.deviceMemory,
            "screen": Belt.Int.toString(Screen.width) ++
            "x" ++
            Belt.Int.toString(Screen.height) ++
            " (" ++
            Float.toString(Screen.devicePixelRatio) ++ "x)",
            "gpu": {"renderer": renderer, "vendor": vendor},
            "url": getHref(),
            "version": %raw(`typeof window.APP_VERSION !== 'undefined' ? window.APP_VERSION : 'unknown'`),
          }),
          (),
        )
      } catch {
      | _ => Logger.warn(~module_="Main", ~message="Failed to collect system telemetry", ())
      }

      // 4. Dom Setup & Mount

      Logger.info(~module_="Main", ~message="Mounting App...", ())
      switch Dom.getElementById("app")->Nullable.toOption {
      | Some(appRoot) =>
        let root = ReactDOMClient.createRoot(appRoot)
        ReactDOMClient.Root.render(root, <App />)
        Logger.info(~module_="Main", ~message="App Mounted", ())
      | None => Logger.error(~module_="Main", ~message="Root element #app not found", ())
      }

      // 7. Systems
      AudioManager.setupGlobalClickSounds()
      // VisualPipeline.init("visual-pipeline-container")->ignore
      Logger.info(~module_="Main", ~message="Systems Initialized", ())
      // SimulationSystem.initSimulationKeyHandler() - Deprecated
      ImageOptimizer.init()

      // 8. Service Worker (for offline capability and caching)
      try {
        if Constants.isDebugBuild() {
          ServiceWorker.unregisterServiceWorker()
          Logger.info(~module_="Main", ~message="Service Worker Unregistered (Dev Mode)", ())
        } else {
          ServiceWorker.registerServiceWorker()
        }
      } catch {
      | _ =>
        Logger.warn(~module_="Main", ~message="Failed to configure Service Worker", ())
        // Force unregister in case of uncertainty to be safe
        ServiceWorker.unregisterServiceWorker()
      }

      // 8. Global click handler
      // 9. Persistence & Session Recovery
      PersistenceLayer.initSubscriber()

      // Register Recovery Handlers
      RecoveryManager.registerHandler("SaveProject", ProjectManager.recoverSaveProject)

      let _recovered = await PersistenceLayer.checkRecovery()

      let journal = await OperationJournal.load()
      let interrupted = OperationJournal.getInterrupted(journal)

      if Array.length(interrupted) > 0 {
        let clearInterrupted = () => {
          Belt.Array.forEach(interrupted, entry => {
            OperationJournal.updateStatus(entry.id, Cancelled)
          })
          EventBus.dispatch(CloseModal)
        }

        let retryAll = entries => {
          EventBus.dispatch(CloseModal)
          Belt.Array.forEach(entries, entry => {
            let _ = RecoveryManager.retry(entry)
          })
        }

        EventBus.dispatch(
          ShowModal({
            title: "Interrupted Operations Detected",
            description: Some("The app closed unexpectedly while operations were in progress."),
            content: Some(<RecoveryPrompt entries={interrupted} />),
            buttons: [
              {
                label: "Retry All",
                class_: "btn-primary",
                onClick: () => retryAll(interrupted),
                autoClose: Some(false),
              },
              {
                label: "Dismiss",
                class_: "btn-secondary",
                onClick: () => clearInterrupted(),
                autoClose: Some(false),
              },
            ],
            icon: Some("alert-triangle"),
            allowClose: Some(true),
            onClose: None,
            className: None,
          }),
        )
      }

      /*
      switch recovered {
      | Some(session) =>
        let dateStr = Date.fromTime(session.timestamp)->Date.toLocaleString
        EventBus.dispatch(
          ShowModal({
            title: "Unsaved Session Found",
            description: Some(
              "We found an unsaved session from " ++ dateStr ++ ". Would you like to restore it?",
            ),
            content: None,
            icon: Some("history"),
            allowClose: Some(false),
            onClose: None,
            className: Some("modal-blue"),
            buttons: [
              {
                label: "Restore",
                class_: "bg-blue-500/20 text-white hover:bg-blue-500/40",
                onClick: () => {
                  GlobalStateBridge.dispatch(LoadProject(session.projectData))
                  EventBus.dispatch(ShowNotification("Session Restored", #Success, None))
                },
                autoClose: Some(true),
              },
              {
                label: "Discard",
                class_: "bg-slate-100/10 text-white hover:bg-white/20",
                onClick: () => {
                  PersistenceLayer.clearSession()
                  EventBus.dispatch(ShowNotification("Session Discarded", #Info, None))
                },
                autoClose: Some(true),
              },
            ],
          }),
        )
      | None => ()
      }
 */

      // 8. Global click handler
      Dom.addEventListener(docToEl(Dom.document), "viewer-click", (e: Dom.event) => {
        let state = GlobalStateBridge.getState()
        if state.isLinking {
          let customEvent = ViewerClickEvent.fromEvent(e)
          let detail = ViewerClickEvent.detail(customEvent)

          switch state.linkDraft {
          | None =>
            let newDraft: Types.linkDraft = {
              pitch: detail.pitch,
              yaw: detail.yaw,
              camPitch: detail.camPitch,
              camYaw: detail.camYaw,
              camHfov: detail.camHfov,
              intermediatePoints: Some([]),
            }
            GlobalStateBridge.dispatch(Actions.UpdateLinkDraft(newDraft))

          | Some(current) =>
            let newPoint: Types.linkDraft = {
              pitch: detail.pitch,
              yaw: detail.yaw,
              camPitch: detail.camPitch,
              camYaw: detail.camYaw,
              camHfov: detail.camHfov,
              intermediatePoints: None,
            }

            let currentPoints = switch current.intermediatePoints {
            | Some(pts) => pts
            | None => []
            }

            let updatedDraft = {
              ...current,
              intermediatePoints: Some(Belt.Array.concat(currentPoints, [newPoint])),
            }
            GlobalStateBridge.dispatch(Actions.UpdateLinkDraft(updatedDraft))
          }
        }
      })
    } catch {
    | exn =>
      let (msg, stack) = Logger.getErrorDetails(exn)
      Logger.error(
        ~module_="System",
        ~message="CRITICAL_INIT_FAILURE",
        ~data={"error": msg, "stack": stack},
        (),
      )
    }
  }
}

let _ = init()
