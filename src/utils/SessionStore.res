open Types
open RescriptSchema

@val @scope("localStorage")
external setItem: (string, string) => unit = "setItem"

@val @scope("localStorage")
external getItem: string => Nullable.t<string> = "getItem"

@val @scope("localStorage")
external removeItem: string => unit = "removeItem"

@val @scope("JSON")
external stringify: 'a => string = "stringify"

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
    /*
      NOTE: We use JSON.stringify here instead of S.reverseConvertToJsonStringOrThrow
      because the current version of rescript-schema (9.3.4) throws an internal TypeError
      ("Cannot set properties of undefined (setting '~r')") when reverse converting this object in the test environment.
      Since the sessionState record fields map 1:1 to the JSON keys defined in the schema,
      JSON.stringify is safe and produces compatible JSON for the parser.
    */
    let str = stringify(sessionState)
    setItem(storageKey, str)
  } catch {
  | JsExn(e) =>
    Logger.error(
      ~module_="SessionStore",
      ~message="SessionStore Save Exn",
      ~data=Logger.castToJson({"error": e}),
      (),
    )
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
