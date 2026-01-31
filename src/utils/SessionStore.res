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
  | S.Raised(e) => Console.error("SessionStore Save Error: " ++ S.Error.message(e))
  | Js.Exn.Error(e) => Console.error2("SessionStore Save Exn: ", e)
  | _ => Console.error("SessionStore Save Error: Unknown")
  }
}

let decodeSessionState = (jsonStr: string): option<sessionState> => {
  try {
    Some(S.parseJsonStringOrThrow(jsonStr, Schemas.Domain.sessionState))
  } catch {
  | S.Raised(e) =>
      Console.error("SessionStore Decode Error: " ++ S.Error.message(e))
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
