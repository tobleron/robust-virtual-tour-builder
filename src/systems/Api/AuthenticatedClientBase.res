/* src/systems/Api/AuthenticatedClientBase.res */
open ReBindings

type headers
@send external getHeader: (headers, string) => Nullable.t<string> = "get"

type response = {
  status: int,
  statusText: string,
  json: unit => Promise.t<JSON.t>,
  text: unit => Promise.t<string>,
  blob: unit => Promise.t<Blob.t>,
  headers: headers,
}

@val external fetch: (string, 'options) => Promise.t<response> = "fetch"

let fetchJson = (res: response) => res.json()
let fetchText = (res: response) => res.text()
let fetchBlob = (res: response) => res.blob()

external castBody: 'a => JSON.t = "%identity"
let toUpper: string => string = %raw("(s) => String(s || '').toUpperCase()")

let circuitBreaker = CircuitBreaker.make()
let getDomainCircuitBreaker = domain => CircuitBreakerRegistry.getBreaker(domain)

let getTimeoutMs = (~method: string, ~url: string): int => {
  // Long-running media/project endpoints need larger budgets than generic API calls.
  if (
    String.includes(url, "/api/media/process-full") ||
    String.includes(url, "/api/media/resize-batch") ||
    String.includes(url, "/api/project/import")
  ) {
    180000
  } else {
    switch toUpper(method) {
    | "GET"
    | "HEAD" => 10000
    | "DELETE" => 15000
    | "POST"
    | "PUT"
    | "PATCH" => 25000
    | _ => 15000
    }
  }
}

type requestSignalScope = {
  signal: ReBindings.AbortSignal.t,
  cleanup: unit => unit,
  wasTimedOut: unit => bool,
}

let prepareRequestSignal = (
  ~parentSignal: option<ReBindings.AbortSignal.t>,
  ~timeoutMs: int,
): requestSignalScope => {
  let controller = ReBindings.AbortController.make()
  let requestSignal = ReBindings.AbortController.signal(controller)
  let timedOut = ref(false)
  let cleaned = ref(false)
  let timeoutId = ref(None)

  let onParentAbort = () => {
    // Do not set cleaned := true here to allow cleanup() to run fully
    switch timeoutId.contents {
    | Some(id) => ReBindings.Window.clearTimeout(id)
    | None => ()
    }
    ReBindings.AbortController.abort(controller)
  }

  switch parentSignal {
  | Some(s) =>
    if ReBindings.AbortSignal.aborted(s) {
      ReBindings.AbortController.abort(controller)
    } else {
      s->ReBindings.AbortSignal.addEventListener("abort", onParentAbort)
    }
  | None => ()
  }

  timeoutId := Some(ReBindings.Window.setTimeout(() => {
        if !cleaned.contents {
          timedOut := true
          cleaned := true
          ReBindings.AbortController.abort(controller)
          // Remove parent listener on timeout too
          Option.forEach(parentSignal, s =>
            s->ReBindings.AbortSignal.removeEventListener("abort", onParentAbort)
          )
        }
      }, timeoutMs))

  let cleanup = () => {
    if !cleaned.contents {
      cleaned := true
      switch timeoutId.contents {
      | Some(id) => ReBindings.Window.clearTimeout(id)
      | None => ()
      }
      Option.forEach(parentSignal, s =>
        s->ReBindings.AbortSignal.removeEventListener("abort", onParentAbort)
      )
    }
  }

  {signal: requestSignal, cleanup, wasTimedOut: () => timedOut.contents}
}

let prepareRequestBody = (body: option<JSON.t>, headers: Dict.t<string>): option<string> => {
  switch body {
  | Some(b) =>
    if Dict.get(headers, "Content-Type") == None {
      Dict.set(headers, "Content-Type", "application/json")
    }
    Some(JsonCombinators.Json.stringify(b))
  | None => None
  }
}
