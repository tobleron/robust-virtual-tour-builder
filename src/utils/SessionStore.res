open Types

type sessionState = {
  tourName: string,
  activeIndex: int,
  activeYaw: float,
  activePitch: float,
  isLinking: bool,
  isTeasing: bool,
}

@val @scope("localStorage")
external setItem: (string, string) => unit = "setItem"

@val @scope("localStorage")
external getItem: string => Nullable.t<string> = "getItem"

@val @scope("localStorage")
external removeItem: string => unit = "removeItem"

let storageKey = "vtb_session_store"

let saveState = (state: state) => {
  let sessionState = {
    tourName: state.tourName,
    activeIndex: state.activeIndex,
    activeYaw: state.activeYaw,
    activePitch: state.activePitch,
    isLinking: state.isLinking,
    isTeasing: state.isTeasing,
  }

  try {
    let json = JSON.stringifyAny(sessionState)
    switch json {
    | Some(str) => setItem(storageKey, str)
    | None => ()
    }
  } catch {
  | _ => () // Fallback for private mode or quota exceeded
  }
}

let decodeSessionState = (jsonStr: string): option<sessionState> => {
  switch JSON.parseOrThrow(jsonStr)->JSON.Decode.object {
  | Some(obj) =>
    Some({
      tourName: obj->Dict.get("tourName")->Option.flatMap(JSON.Decode.string)->Option.getOr(""),
      activeIndex: obj
      ->Dict.get("activeIndex")
      ->Option.flatMap(JSON.Decode.float)
      ->Option.map(Float.toInt)
      ->Option.getOr(-1),
      activeYaw: obj->Dict.get("activeYaw")->Option.flatMap(JSON.Decode.float)->Option.getOr(0.0),
      activePitch: obj
      ->Dict.get("activePitch")
      ->Option.flatMap(JSON.Decode.float)
      ->Option.getOr(0.0),
      isLinking: obj
      ->Dict.get("isLinking")
      ->Option.flatMap(JSON.Decode.bool)
      ->Option.getOr(false),
      isTeasing: obj
      ->Dict.get("isTeasing")
      ->Option.flatMap(JSON.Decode.bool)
      ->Option.getOr(false),
    })
  | None => None
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
