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

module JsError = {
  type t
  @get external message: t => string = "message"
  @get external stack: t => Nullable.t<string> = "stack"
  @get external name: t => string = "name"
}

module UnhandledRejectionEvent = {
  type t
  type reason
  @get external getReason: t => reason = "reason"
  @get external getPromise: t => Promise.t<'a> = "promise"
  @send external preventDefault: t => unit = "preventDefault"
  
  external reasonToError: reason => JsError.t = "%identity"
  external reasonToString: reason => string = "%identity"
  let isError: reason => bool = %raw(`function(r) { return r instanceof Error }`)
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

@val @scope("window") external setOnerror: (
  (string, string, int, int, Nullable.t<JsError.t>) => bool
) => unit = "onerror"

@val @scope("window") external setOnunhandledrejection: (
  UnhandledRejectionEvent.t => unit
) => unit = "onunhandledrejection"

@val @scope(("window", "location")) external getHref: unit => string = "toString"

external docToEl: {..} => Dom.element = "%identity"

// --- INITIALIZATION ---

let init = async () => {
  // 1. Logger
  Logger.init()
  
  Logger.info(~module_="System", ~message="Initializing Remax Builder...", ())

  // 2. Global JSON store access (for legacy scripts/console)
  let _ = %raw(`
    window.store = {
      get state() { return GlobalStateBridge.getState(); }
    }
  `)

  // 3. Telemetry
  try {
    let canvas = Dom.createElement("canvas")
    let glOpt = WebGL.getContext(canvas, "webgl")
    
    let (renderer, vendor) = switch glOpt->Nullable.toOption {
    | Some(gl) =>
      let debugInfo = WebGL.getExtension(gl, "WEBGL_debug_renderer_info")
      switch debugInfo->Nullable.toOption {
      | Some(ext) =>
        (
          gl->WebGL.getParameter(WebGLDebugInfo.unmaskedRendererWebgl(ext)),
          gl->WebGL.getParameter(WebGLDebugInfo.unmaskedVendorWebgl(ext))
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
        "screen": Belt.Int.toString(Screen.width) ++ "x" ++ Belt.Int.toString(Screen.height) ++ " (" ++ Float.toString(Screen.devicePixelRatio) ++ "x)",
        "gpu": {"renderer": renderer, "vendor": vendor},
        "url": getHref(),
        "version": %raw(`typeof window.APP_VERSION !== 'undefined' ? window.APP_VERSION : 'unknown'`)
      }),
      ()
    )
  } catch {
  | _ => Console.warn("Failed to collect system telemetry")
  }

  // 4. Error Handlers
  setOnerror((message, source, lineno, colno, error) => {
    Logger.error(
      ~module_="Global",
      ~message="Uncaught Error: " ++ message,
      ~data=Some({
        "source": source,
        "lineno": lineno,
        "colno": colno,
        "stack": switch error->Nullable.toOption {
        | Some(e) => JsError.stack(e)->Nullable.toOption->Option.getOr("")
        | None => ""
        },
        "type": switch error->Nullable.toOption {
        | Some(e) => JsError.name(e)
        | None => "Error"
        }
      }),
      ()
    )
    false
  })

  setOnunhandledrejection(event => {
    let reason = UnhandledRejectionEvent.getReason(event)
    let isError = UnhandledRejectionEvent.isError(reason)
    
    Logger.error(
      ~module_="Global",
      ~message="Unhandled Promise Rejection",
      ~data=Some({
        "reason": isError 
          ? JsError.message(UnhandledRejectionEvent.reasonToError(reason))
          : UnhandledRejectionEvent.reasonToString(reason),
        "stack": isError 
          ? JsError.stack(UnhandledRejectionEvent.reasonToError(reason))
          : Nullable.null,
        "promise": UnhandledRejectionEvent.getPromise(event)
      }),
      ()
    )

    if !Js.String.includes("localhost", Window.window["location"]["hostname"]) {
      UnhandledRejectionEvent.preventDefault(event)
    }
  })

  // 5. Dom Setup & Mount
  switch Dom.getElementById("app")->Nullable.toOption {
  | Some(appRoot) =>
    let root = ReactDOMClient.createRoot(appRoot)
    ReactDOMClient.Root.render(root, <App />)
  | None => Console.error("Root element #app not found")
  }


  // 7. Systems
  AudioManager.setupGlobalClickSounds()
  VisualPipeline.init("visual-pipeline-container")->ignore
  SimulationSystem.initSimulationKeyHandler()
  InputSystem.initInputSystem()
  
  // 8. Service Worker (for offline capability and caching)
  ServiceWorker.registerServiceWorker()
  
  // 8. Global click handler
  // 8. Global click handler
  Dom.addEventListener(docToEl(Dom.document), "viewer-click", (e: Dom.event) => {
    if GlobalStateBridge.getState().isLinking {
      let customEvent = ViewerClickEvent.fromEvent(e)
      let detail = ViewerClickEvent.detail(customEvent)
      LinkModal.showLinkModal(
        ~pitch=detail.pitch,
        ~yaw=detail.yaw,
        ~camPitch=detail.camPitch,
        ~camYaw=detail.camYaw,
        ~camHfov=detail.camHfov,
        ()
      )
    }
  })
}

let _ = init()
