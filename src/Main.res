/* src/Main.res */

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
  try {
    // 1. Logger (Now handles all global error trapping)
    Logger.init()

    Logger.info(~module_="System", ~message="Initializing Remax Builder...", ())
    Logger.info(~module_="Main", ~message="Main Init Started", ())

    // Verify Global Dependencies
    let hasPannellum: bool = %raw("typeof window.pannellum !== 'undefined'")
    if hasPannellum {
      Logger.info(~module_="System", ~message="Pannellum Global Found", ())
      Logger.info(~module_="Main", ~message="Pannellum Found", ())
    } else {
      Logger.error(~module_="System", ~message="Pannellum Global MISSING", ())
      Console.error("Pannellum MISSING")
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
    | _ => Console.warn("Failed to collect system telemetry")
    }

    // 4. Dom Setup & Mount

    Logger.info(~module_="Main", ~message="Mounting App...", ())
    switch Dom.getElementById("app")->Nullable.toOption {
    | Some(appRoot) =>
      let root = ReactDOMClient.createRoot(appRoot)
      ReactDOMClient.Root.render(root, <App />)
      Logger.info(~module_="Main", ~message="App Mounted", ())
    | None => Console.error("Root element #app not found")
    }

    // 7. Systems
    AudioManager.setupGlobalClickSounds()
    // VisualPipeline.init("visual-pipeline-container")->ignore
    Logger.info(~module_="Main", ~message="Systems Initialized", ())
    // SimulationSystem.initSimulationKeyHandler() - Deprecated
    InputSystem.initInputSystem()
    ImageOptimizer.init()

    // 8. Service Worker (for offline capability and caching)
    try {
      if Constants.isDebugBuild() {
        ServiceWorker.unregisterServiceWorker()
        Console.log("Service Worker Unregistered (Dev Mode)")
      } else {
        ServiceWorker.registerServiceWorker()
      }
    } catch {
    | _ =>
      Console.warn("Failed to configure Service Worker")
      // Force unregister in case of uncertainty to be safe
      ServiceWorker.unregisterServiceWorker()
    }

    // 8. Global click handler
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
    Console.error("CRITICAL INIT ERROR: " ++ msg)
    Logger.error(
      ~module_="System",
      ~message="CRITICAL_INIT_FAILURE",
      ~data={"error": msg, "stack": stack},
      (),
    )
  }
}

let _ = init()
