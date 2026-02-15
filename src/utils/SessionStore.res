open Types

@val @scope("localStorage")
external setItem: (string, string) => unit = "setItem"

@val @scope("localStorage")
external getItem: string => Nullable.t<string> = "getItem"

@val @scope("localStorage")
external removeItem: string => unit = "removeItem"

let storageKey = "vtb_session_store"

let save = (sessionState: sessionState) => {
  try {
    let str = JsonCombinators.Json.stringify(JsonParsers.Domain.SessionState.encode(sessionState))
    setItem(storageKey, str)
  } catch {
  | e => {
      let (msg, stack) = Logger.getErrorDetails(e)
      Logger.error(
        ~module_="SessionStore",
        ~message="SessionStore Save Exn",
        ~data=Logger.castToJson({"error": msg, "stack": stack}),
        (),
      )
    }
  }
}

let saveState = (state: state) => {
  let sessionState: sessionState = {
    tourName: state.tourName,
    activeIndex: state.activeIndex,
    activeYaw: state.activeYaw,
    activePitch: state.activePitch,
    isLinking: state.isLinking,
    isTeasing: state.isTeasing,
  }

  save(sessionState)
}

let decodeSessionState = (jsonStr: string): option<sessionState> => {
  switch JsonCombinators.Json.parse(jsonStr) {
  | Ok(json) =>
    switch JsonCombinators.Json.decode(json, JsonParsers.Domain.SessionState.decode) {
    | Ok(s) => Some(s)
    | Error(e) => {
        Logger.error(~module_="SessionStore", ~message="SessionStore Decode Error: " ++ e, ())
        None
      }
    }
  | Error(e) => {
      Logger.error(~module_="SessionStore", ~message="SessionStore Parse Error: " ++ e, ())
      None
    }
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
