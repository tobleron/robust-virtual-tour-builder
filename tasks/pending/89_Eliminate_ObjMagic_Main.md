# Task 89: Eliminate Obj.magic in Main.res

## Priority
**HIGH** - Type safety issue that bypasses compiler checks

## Context
`Main.res` currently uses `Obj.magic` in several places to access browser APIs and error objects. This bypasses ReScript's type checker and introduces potential runtime inconsistencies.

## Current Issues

### 1. WebGL Extension Access (Lines 63-64)
```rescript
gl->WebGL.getParameter(Obj.magic(ext)["UNMASKED_RENDERER_WEBGL"]),
gl->WebGL.getParameter(Obj.magic(ext)["UNMASKED_VENDOR_WEBGL"])
```

### 2. Error Object Access (Lines 100, 104)
```rescript
"stack": switch error->Nullable.toOption {
  | Some(e) => (Obj.magic(e): {..})["stack"]
  | None => ""
},
"type": switch error->Nullable.toOption {
  | Some(e) => (Obj.magic(e): {..})["name"]
  | None => "Error"
}
```

### 3. Promise Rejection Event (Lines 114, 122-123)
```rescript
let reason = event["reason"]
let isError = %raw(`reason instanceof Error`)
// ...
"reason": isError ? reason["message"] : reason,
"stack": isError ? reason["stack"] : Nullable.null,
```

### 4. Custom Event Detail (Line 154)
```rescript
let detail = (Obj.magic(e): {..})["detail"]
```

### 5. ReactDOM Root Creation (Line 136)
```rescript
let root = ReactDOM.Client.createRoot(Obj.magic(appRoot))
```

## Goals

1. **Define Proper External Bindings**:
   - Create typed bindings for WebGL debug extension constants
   - Create typed bindings for JavaScript Error objects
   - Create typed bindings for UnhandledRejection events
   - Create typed bindings for CustomEvent with detail payload
   - Fix ReactDOM.Client.createRoot binding

2. **Replace All Obj.magic Calls**:
   - Use proper external bindings instead of `Obj.magic`
   - Ensure type safety at the FFI boundary
   - Maintain existing functionality

3. **Verify Correctness**:
   - Application starts without errors
   - Telemetry logging works correctly
   - Error handlers capture stack traces
   - Viewer click events work properly

## Implementation Steps

### Step 1: Create WebGL Bindings
In `Main.res`, add proper bindings for the debug extension:

```rescript
module WebGLDebugInfo = {
  type t
  @get external unmaskedRendererWebgl: t => int = "UNMASKED_RENDERER_WEBGL"
  @get external unmaskedVendorWebgl: t => int = "UNMASKED_VENDOR_WEBGL"
}
```

Update the WebGL module to properly type the extension:
```rescript
module WebGL = {
  type t
  @send external getContext: (Dom.element, string) => Nullable.t<t> = "getContext"
  @send external getExtension: (t, string) => Nullable.t<WebGLDebugInfo.t> = "getExtension"
  @send external getParameter: (t, int) => string = "getParameter"
}
```

### Step 2: Create Error Object Bindings
```rescript
module JsError = {
  type t
  @get external message: t => string = "message"
  @get external stack: t => Nullable.t<string> = "stack"
  @get external name: t => string = "name"
}
```

### Step 3: Create UnhandledRejection Event Bindings
```rescript
module UnhandledRejectionEvent = {
  type t
  type reason
  @get external getReason: t => reason = "reason"
  @get external getPromise: t => Promise.t<'a> = "promise"
  @send external preventDefault: t => unit = "preventDefault"
  
  external reasonToError: reason => JsError.t = "%identity"
  external reasonToString: reason => string = "%identity"
  @val external isError: reason => bool = "instanceof Error"
}
```

### Step 4: Create CustomEvent Bindings
```rescript
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
}
```

### Step 5: Fix ReactDOM Binding
Update the ReactDOM binding in `ReBindings.res`:
```rescript
module Client = {
  type root
  @module("react-dom/client") @scope("default")
  external createRoot: Dom.element => root = "createRoot"
  
  module Root = {
    @send external render: (root, React.element) => unit = "render"
  }
}
```

### Step 6: Update Main.res to Use New Bindings

Replace the WebGL section:
```rescript
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
```

Replace error handling:
```rescript
setOnerror((message, source, lineno, colno, error) => {
  Logger.error(
    ~module_="Global",
    ~message="Uncaught Error: " ++ message,
    ~data=Some({
      "source": source,
      "lineno": lineno,
      "colno": colno,
      "stack": switch error->Nullable.toOption {
        | Some(e) => JsError.stack(e)->Nullable.toOption->Option.getWithDefault("")
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
```

Replace unhandled rejection:
```rescript
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
```

Replace viewer click event:
```rescript
Dom.addEventListener(Obj.magic(Dom.document), "viewer-click", (e: Dom.event) => {
  if GlobalStateBridge.getState().isLinking {
    let customEvent = (e :> ViewerClickEvent.t)
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
```

Replace ReactDOM root:
```rescript
switch Dom.getElementById("app")->Nullable.toOption {
| Some(appRoot) =>
  let root = ReactDOM.Client.createRoot(appRoot)
  ReactDOM.Client.Root.render(root, <App />)
| None => Console.error("Root element #app not found")
}
```

## Verification

1. **Build Check**:
   ```bash
   npm run res:build
   ```
   Should complete without errors or warnings.

2. **Runtime Verification**:
   - Start the application
   - Check browser console for telemetry log with GPU info
   - Trigger an error and verify stack trace is captured
   - Create a promise rejection and verify it's logged
   - Click on viewer in linking mode and verify modal appears

3. **Type Safety**:
   - Search codebase for `Obj.magic` in `Main.res`
   - Should only remain if absolutely necessary (document why)

## Success Criteria

- [ ] All WebGL bindings are properly typed
- [ ] Error object access uses typed bindings
- [ ] UnhandledRejection event uses typed bindings
- [ ] CustomEvent detail access uses typed bindings
- [ ] ReactDOM.Client.createRoot uses proper binding
- [ ] No `Obj.magic` calls remain in `Main.res` (or documented exceptions)
- [ ] `npm run res:build` succeeds without warnings
- [ ] Application starts and logs telemetry correctly
- [ ] Error handlers capture full error information
- [ ] Viewer click events work as expected

## Notes

- This task focuses specifically on `Main.res`. Other modules may have their own `Obj.magic` usage that should be addressed separately.
- The bindings created here may be useful in other parts of the codebase.
- Consider moving reusable bindings (like `JsError`) to `ReBindings.res` for project-wide use.
