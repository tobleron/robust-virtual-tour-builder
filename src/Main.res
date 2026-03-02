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
      NavigationSupervisor.configure(AppStateBridge.dispatch)

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

      // 8. Network Status
      NetworkStatus.initialize()
      RequestQueue.initializeNetworkListener()

      let _ = EventBus.subscribe(event => {
        switch event {
        | RateLimitBackoff(seconds) => RequestQueue.handleRateLimit(seconds)
        | _ => ()
        }
      })

      // 9. Service Worker (for offline capability and caching)
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

      AppStateBridge.onReady(() => {
        PersistenceLayer.initSubscriber(
          ~getState=AppStateBridge.getState,
          ~onChange=PersistenceLayer.notifyStateChange,
          ~subscribe=AppStateBridge.subscribe,
        )

        RecoveryManager.registerHandler(
          "SaveProject",
          ProjectManager.recoverSaveProject(
            ~getState=AppStateBridge.getState,
            ~dispatch=AppStateBridge.dispatch,
            ~subscribe=AppStateBridge.subscribe,
          ),
        )
        RecoveryManager.registerHandler("UploadImages", UploadProcessorLogic.recoverUpload)

        let _ = PersistenceLayer.checkRecovery()->Promise.catch(_ => Promise.resolve(None))
      })

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
                  AppStateBridge.dispatch(LoadProject(session.projectData))
                  NotificationManager.dispatch({
                    id: "",
                    importance: Success,
                    context: SystemEvent("session"),
                    message: "Session Restored",
                    details: None,
                    action: None,
                    duration: NotificationTypes.defaultTimeoutMs(Success),
                    dismissible: true,
                    createdAt: Date.now(),
                  })
                },
                autoClose: Some(true),
              },
              {
                label: "Discard",
                class_: "bg-slate-100/10 text-white hover:bg-white/20",
                onClick: () => {
                  PersistenceLayer.clearSession()
                  NotificationManager.dispatch({
                    id: "",
                    importance: Info,
                    context: SystemEvent("session"),
                    message: "Session Discarded",
                    details: None,
                    action: None,
                    duration: NotificationTypes.defaultTimeoutMs(Info),
                    dismissible: true,
                    createdAt: Date.now(),
                  })
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
        Logger.debug(~module_="Main", ~message="VIEWER_CLICK_RECEIVED", ())
        if !AppStateBridge.isReady() {
          Logger.warn(~module_="Main", ~message="VIEWER_CLICK_BEFORE_CONTEXT_READY", ())
          ()
        } else {
          let state = AppStateBridge.getState()

          switch state.movingHotspot {
          | Some({sceneIndex, hotspotIndex}) => {
              let customEvent = ViewerClickEvent.fromEvent(e)
              let detail = ViewerClickEvent.detail(customEvent)

              let clampPitch = (pitch: float): float => {
                if pitch > 89.0 {
                  89.0
                } else if pitch < -89.0 {
                  -89.0
                } else {
                  pitch
                }
              }

              let detailCoords: option<(float, float)> = if (
                Float.isFinite(detail.yaw) && Float.isFinite(detail.pitch)
              ) {
                Some((detail.yaw, detail.pitch))
              } else {
                None
              }

              let fallbackCoords = switch (
                Nullable.toOption(ViewerSystem.getActiveViewer()),
                ViewerState.state.contents.lastMouseEvent->Nullable.toOption,
              ) {
              | (Some(viewer), Some(lastMouseEvent)) =>
                let mouseEvent: Viewer.mouseEvent = {
                  "clientX": Belt.Int.toFloat(Dom.clientX(lastMouseEvent)),
                  "clientY": Belt.Int.toFloat(Dom.clientY(lastMouseEvent)),
                }
                let coords = Viewer.mouseEventToCoords(viewer, mouseEvent)
                switch (Belt.Array.get(coords, 1), Belt.Array.get(coords, 0)) {
                | (Some(yaw), Some(pitch)) if Float.isFinite(yaw) && Float.isFinite(pitch) =>
                  Some((yaw, pitch))
                | _ => None
                }
              | _ => None
              }

              let resolvedCoords = switch detailCoords {
              | Some(coords) => Some(coords)
              | None => fallbackCoords
              }

              switch resolvedCoords {
              | Some((yaw, pitch)) =>
                HotspotManager.handleCommitHotspotMove(
                  sceneIndex,
                  hotspotIndex,
                  yaw,
                  clampPitch(pitch),
                )->ignore
              | None =>
                Logger.warn(
                  ~module_="Main",
                  ~message="HOTSPOT_MOVE_INVALID_COORDS_IGNORED",
                  ~data=Some({
                    "sceneIndex": sceneIndex,
                    "hotspotIndex": hotspotIndex,
                    "detailYaw": detail.yaw,
                    "detailPitch": detail.pitch,
                  }),
                  (),
                )
              }
            }
          | None =>
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
                  retargetHotspot: None,
                }
                AppStateBridge.dispatch(Actions.UpdateLinkDraft(newDraft))

              | Some(current) =>
                let newPoint: Types.linkDraft = {
                  pitch: detail.pitch,
                  yaw: detail.yaw,
                  camPitch: detail.camPitch,
                  camYaw: detail.camYaw,
                  camHfov: detail.camHfov,
                  intermediatePoints: None,
                  retargetHotspot: None,
                }

                let currentPoints = switch current.intermediatePoints {
                | Some(pts) => pts
                | None => []
                }

                let updatedDraft = {
                  ...current,
                  intermediatePoints: Some(Belt.Array.concat(currentPoints, [newPoint])),
                }
                AppStateBridge.dispatch(Actions.UpdateLinkDraft(updatedDraft))
              }
            }
          }
        }
      })

      Logger.info(~module_="Main", ~message="MAIN_INIT_DONE_WAITING_FOR_APP", ())
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
