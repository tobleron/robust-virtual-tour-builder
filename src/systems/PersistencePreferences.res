open ReBindings

type autosaveMode =
  | Off
  | LocalOnly
  | Hybrid

type snapshotCadence =
  | Conservative
  | Balanced
  | Frequent

type saveTarget =
  | Offline
  | Server
  | Both

type t = {
  autosaveMode: autosaveMode,
  snapshotCadence: snapshotCadence,
  preferredSaveTarget: saveTarget,
}

type decoded = {
  autosaveMode: string,
  snapshotCadence: string,
  preferredSaveTarget: string,
}

let storageKey = "vtb_persistence_preferences_v1"

let default: t = {
  autosaveMode: Hybrid,
  snapshotCadence: Balanced,
  preferredSaveTarget: Server,
}

let autosaveModeToString = mode =>
  switch mode {
  | Off => "off"
  | LocalOnly => "local-only"
  | Hybrid => "hybrid"
  }

let autosaveModeFromString = value =>
  switch value {
  | "off" => Off
  | "local-only" => LocalOnly
  | "hybrid" => Hybrid
  | _ => default.autosaveMode
  }

let snapshotCadenceToString = cadence =>
  switch cadence {
  | Conservative => "conservative"
  | Balanced => "balanced"
  | Frequent => "frequent"
  }

let snapshotCadenceFromString = value =>
  switch value {
  | "conservative" => Conservative
  | "balanced" => Balanced
  | "frequent" => Frequent
  | _ => default.snapshotCadence
  }

let saveTargetToString = target =>
  switch target {
  | Offline => "offline"
  | Server => "server"
  | Both => "both"
  }

let saveTargetFromString = value =>
  switch value {
  | "offline" => Offline
  | "server" => Server
  | "both" => Both
  | _ => default.preferredSaveTarget
  }

let encode = (prefs: t) =>
  JsonCombinators.Json.Encode.object([
    ("autosaveMode", JsonCombinators.Json.Encode.string(autosaveModeToString(prefs.autosaveMode))),
    (
      "snapshotCadence",
      JsonCombinators.Json.Encode.string(snapshotCadenceToString(prefs.snapshotCadence)),
    ),
    (
      "preferredSaveTarget",
      JsonCombinators.Json.Encode.string(saveTargetToString(prefs.preferredSaveTarget)),
    ),
  ])

let decode = json =>
  JsonCombinators.Json.decode(
    json,
    JsonCombinators.Json.Decode.object((field): decoded => {
      autosaveMode: field.required("autosaveMode", JsonCombinators.Json.Decode.string),
      snapshotCadence: field.required("snapshotCadence", JsonCombinators.Json.Decode.string),
      preferredSaveTarget: field.required(
        "preferredSaveTarget",
        JsonCombinators.Json.Decode.string,
      ),
    }),
  )

let get = (): t => {
  try {
    switch Dom.Storage2.localStorage->Dom.Storage2.getItem(storageKey) {
    | Some(raw) =>
      switch JsonCombinators.Json.parse(raw) {
      | Ok(json) =>
        switch decode(json) {
        | Ok(value) => {
            autosaveMode: autosaveModeFromString(value.autosaveMode),
            snapshotCadence: snapshotCadenceFromString(value.snapshotCadence),
            preferredSaveTarget: saveTargetFromString(value.preferredSaveTarget),
          }
        | Error(_) => default
        }
      | Error(_) => default
      }
    | None => default
    }
  } catch {
  | _ => default
  }
}

let save = (prefs: t) => {
  try {
    let encoded = encode(prefs)->JsonCombinators.Json.stringify
    Dom.Storage2.localStorage->Dom.Storage2.setItem(storageKey, encoded)
    Logger.debug(
      ~module_="PersistencePreferences",
      ~message="PREFERENCES_SAVED",
      ~data=Some(
        Logger.castToJson({
          "autosaveMode": autosaveModeToString(prefs.autosaveMode),
          "snapshotCadence": snapshotCadenceToString(prefs.snapshotCadence),
          "preferredSaveTarget": saveTargetToString(prefs.preferredSaveTarget),
        }),
      ),
      (),
    )
  } catch {
  | _ => ()
  }
}

let update = (fn: t => t): t => {
  let next = fn(get())
  save(next)
  next
}

let setPreferredSaveTarget = preferredSaveTarget => update(prev => {...prev, preferredSaveTarget})

let setAutosave = (~autosaveMode, ~snapshotCadence) =>
  update(prev => {...prev, autosaveMode, snapshotCadence})
