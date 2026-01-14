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

module WebGL = {
  type t
  @send external getContext: (Dom.element, string) => Nullable.t<t> = "getContext"
  @send external getExtension: (t, string) => Nullable.t<{..}> = "getExtension"
  @send external getParameter: (t, 'a) => 'b = "getParameter"
}

@val @scope("window") external setOnerror: (
  (string, string, int, int, Nullable.t<JsExn.t>) => bool
) => unit = "onerror"

@val @scope("window") external setOnunhandledrejection: (
  {..} => unit
) => unit = "onunhandledrejection"

@val @scope(("window", "location")) external getHref: unit => string = "toString"

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
          gl->WebGL.getParameter(Obj.magic(ext)["UNMASKED_RENDERER_WEBGL"]),
          gl->WebGL.getParameter(Obj.magic(ext)["UNMASKED_VENDOR_WEBGL"])
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
                 | Some(e) => (Obj.magic(e): {..})["stack"]
                 | None => ""
                 },
        "type": switch error->Nullable.toOption {
                | Some(e) => (Obj.magic(e): {..})["name"]
                | None => "Error"
                }
      }),
      ()
    )
    false
  })

  setOnunhandledrejection(event => {
    let reason = event["reason"]
    let isError = %raw(`reason instanceof Error`)
    
    Logger.error(
      ~module_="Global",
      ~message="Unhandled Promise Rejection",
      ~data=Some({
        "reason": isError ? reason["message"] : reason,
        "stack": isError ? reason["stack"] : Nullable.null,
        "promise": event["promise"]
      }),
      ()
    )

    if !Js.String.includes("localhost", Window.window["location"]["hostname"]) {
       event["preventDefault"]()
    }
  })

  // 5. Dom Setup & Mount
  switch Dom.getElementById("app")->Nullable.toOption {
  | Some(appRoot) =>
    let root = ReactDOM.Client.createRoot(Obj.magic(appRoot))
    ReactDOM.Client.Root.render(root, <App />)
  | None => Console.error("Root element #app not found")
  }


  // 7. Systems
  AudioManager.setupGlobalClickSounds()
  VisualPipeline.init("visual-pipeline-container")->ignore
  SimulationSystem.initSimulationKeyHandler()
  InputSystem.initInputSystem()
  
  // 8. Global click handler
  Dom.addEventListener(Obj.magic(Dom.document), "viewer-click", (e: Dom.event) => {
    if GlobalStateBridge.getState().isLinking {
      let detail = (Obj.magic(e): {..})["detail"]
      LinkModal.showLinkModal(
        ~pitch=detail["pitch"],
        ~yaw=detail["yaw"],
        ~camPitch=detail["camPitch"],
        ~camYaw=detail["camYaw"],
        ~camHfov=detail["camHfov"],
        ()
      )
    }
  })
}

let _ = init()
