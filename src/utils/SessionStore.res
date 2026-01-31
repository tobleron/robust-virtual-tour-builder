@@warning("-3")
open Types

@val @scope("localStorage")
external setItem: (string, string) => unit = "setItem"

@val @scope("localStorage")
external getItem: string => Nullable.t<string> = "getItem"

@val @scope("localStorage")
external removeItem: string => unit = "removeItem"

let storageKey = "vtb_session_store"

let saveState = (state: state) => {
  let sessionState: sessionState = {
    tourName: state.tourName,
    activeIndex: state.activeIndex,
    activeYaw: state.activeYaw,
    activePitch: state.activePitch,
    isLinking: state.isLinking,
    isTeasing: state.isTeasing,
  }

  try {
    // CSP SAFE FIX: rescript-schema uses `new Function` which violates strict CSP.
    // Using standard JSON.stringify since sessionState is a simple record.
    let str = switch JSON.stringifyAny(sessionState) {
    | Some(s) => s
    | None => {
        Logger.error(~module_="SessionStore", ~message="Failed to stringify session state", ())
        ""
      }
    }
    if str != "" {
      setItem(storageKey, str)
    }
  } catch {
  | Js.Exn.Error(e) => {
      let (msg, stack) = Logger.getErrorDetails(Js.Exn.anyToExnInternal(e))
      Logger.error(
        ~module_="SessionStore",
        ~message="SessionStore Save Exn",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
    }
  | _ => Logger.error(~module_="SessionStore", ~message="SessionStore Save Error: Unknown", ())
  }
}

let decodeSessionState = (jsonStr: string): option<sessionState> => {
  try {
    // CSP SAFE FIX: Using standard parse + cast.
    let json = try {
      JSON.parseOrThrow(jsonStr)
    } catch {
    | _ => JSON.Encode.null
    }

    // Safety check: Ensure it's an object/array before casting
    switch Js.Json.classify(json) {
    | JSONObject(_) | JSONArray(_) => Some(Obj.magic(json))
    | _ => None
    }
  } catch {
  | Js.Exn.Error(e) =>
    Logger.error(
      ~module_="SessionStore",
      ~message="SessionStore Decode Error: " ++ Js.Exn.message(e)->Option.getOr("Unknown"),
      (),
    )
    None
  | _ => None
  }
}

let loadState = (): option<sessionState> => {
  try {
    let item = getItem(storageKey)
    switch item->Nullable.toOption {
    | Some(jsonStr) => decodeSessionState(jsonStr)
    | None => None
    }
  } catch {
  | _ => None
  }
}

let clearState = () => {
  try {
    removeItem(storageKey)
  } catch {
  | _ => ()
  }
}
