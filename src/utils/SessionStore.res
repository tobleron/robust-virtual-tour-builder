open Types
open RescriptSchema

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
    let str = S.reverseConvertToJsonStringOrThrow(sessionState, Schemas.Domain.sessionState)
    setItem(storageKey, str)
  } catch {
  | S.Raised(e) =>
    Logger.error(
      ~module_="SessionStore",
      ~message="SessionStore Save Error: " ++ S.Error.message(e),
      (),
    )
  | JsExn(e) => {
      // Use helper to extract message instead of logging raw 'e'
      let (msg, stack) = Logger.getErrorDetails(JsExn.anyToExnInternal(e))
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
    Some(S.parseJsonStringOrThrow(jsonStr, Schemas.Domain.sessionState))
  } catch {
  | S.Raised(e) =>
    Logger.error(
      ~module_="SessionStore",
      ~message="SessionStore Decode Error: " ++ S.Error.message(e),
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
