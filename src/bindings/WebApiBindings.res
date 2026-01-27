/* src/bindings/WebApiBindings.res */

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
  @send external arrayBuffer: response => Promise.t<BrowserBindings.BrowserArrayBuffer.t> = "arrayBuffer"
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
