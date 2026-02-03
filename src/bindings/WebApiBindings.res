/* src/bindings/WebApiBindings.res */

// Blob is already defined in BrowserBindings.res which is included in ReBindings
// We will alias it here or just use it directly if possible, but since ReBindings includes both,
// and we are inside WebApiBindings, we should refer to the type from BrowserBindings if we want to avoid conflict
// However, WebApiBindings is often used standalone or via ReBindings.
// The conflict happens because ReBindings includes BrowserBindings (defines Blob) AND WebApiBindings (defined Blob).
// Solution: Remove Blob definition from here and rely on BrowserBindings.Blob via type alias if needed,
// OR rename the module here.
// But since we need `make` with specific options, let's extend BrowserBindings.Blob in spirit by just defining the external
// functionality we need without a conflicting module name if possible, or just assume the user uses ReBindings.Blob.
//
// Actually, the cleanest way to fix the conflict in ReBindings (which just includes modules) is to NOT define a module named "Blob" here.

// We will define the external for creating a blob with options here, but not inside a module named "Blob" that conflicts.
// Or we can assume BrowserBindings.Blob.t is the type we want.

@val external sendBeacon: (string, string) => bool = "navigator.sendBeacon"
@val external sendBeaconBlob: (string, BrowserBindings.Blob.t) => bool = "navigator.sendBeacon"
let hasSendBeacon: unit => bool = %raw(`function() { return typeof navigator.sendBeacon === 'function' }`)

module URL = {
  @scope("URL") @val external createObjectURL: 'a => string = "createObjectURL"
  @scope("URL") @val external revokeObjectURL: string => unit = "revokeObjectURL"
}

module Fetch = {
  type response
  type requestInit<'body>
  @obj
  external requestInit: (
    ~method: string,
    ~body: 'body=?,
    ~headers: dict<string>=?,
    ~signal: BrowserBindings.AbortController.signal=?,
    unit,
  ) => requestInit<'body> = ""

  @val external fetch: (string, requestInit<'body>) => Promise.t<response> = "fetch"
  @val external fetchSimple: string => Promise.t<response> = "fetch"

  @send external json: response => Promise.t<'a> = "json"
  @send external text: response => Promise.t<string> = "text"
  @send
  external arrayBuffer: response => Promise.t<BrowserBindings.BrowserArrayBuffer.t> = "arrayBuffer"
  @send external blob: response => Promise.t<BrowserBindings.Blob.t> = "blob"
  @get external ok: response => bool = "ok"
  @get external status: response => int = "status"
  @get external statusText: response => string = "statusText"
}

module FormData = {
  type t
  @new external newFormData: unit => t = "FormData"
  @send external append: (t, string, 'a) => unit = "append"
  @send external appendWithFilename: (t, string, 'a, string) => unit = "append"
}

module Crypto = {
  @val @scope("crypto") external randomUUID: unit => string = "randomUUID"
}
