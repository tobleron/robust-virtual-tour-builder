/* src/utils/PersistenceLayer.res */

open IdbBindings
open Types

type serializedSession = {
  version: int,
  timestamp: float,
  projectData: JSON.t,
}

let key = "autosave_session_latest"
let debounceMs = 2000
let currentSchemaVersion = 2

@val external requestIdleCallback: (unit => unit) => int = "requestIdleCallback"
@val external cancelIdleCallback: int => unit = "cancelIdleCallback"

external asJson: unknown => JSON.t = "%identity"

let stateGetterRef: ref<unit => state> = ref(() => State.initialState)
let lastSaveTimeout = ref(None)
let beforeUnloadListener: ref<option<DomBindings.Dom.event => unit>> = ref(None)
let subscriberRef: ref<option<unit => unit>> = ref(None)

let normalizeProjectData = (projectData: JSON.t): option<JSON.t> => {
  switch JsonCombinators.Json.decode(projectData, JsonParsers.Domain.project) {
  | Ok(project) => Some(JsonParsers.Encoders.project(project))
  | Error(e) =>
    Logger.warn(
      ~module_="Persistence",
      ~message="Persisted project payload failed validation",
      ~data={"error": e},
      (),
    )
    None
  }
}

let performSave = (state: Types.state) => {
  /* Only save if we have scenes or a project name that differs from default */
  let hasContent = Array.length(state.scenes) > 0 || state.tourName != "Tour Name"

  if hasContent {
    let project: Types.project = {
      tourName: state.tourName,
      scenes: state.scenes,
      inventory: state.inventory,
      sceneOrder: state.sceneOrder,
      lastUsedCategory: state.lastUsedCategory,
      exifReport: state.exifReport,
      sessionId: state.sessionId,
      deletedSceneIds: state.deletedSceneIds,
      timeline: state.timeline,
    }

    // Encoded to JSON value using combinators
    let projectData = JsonParsers.Encoders.project(project)
    let timestamp = Date.now()

    let payload = JsonParsers.Encoders.persistedSession(
      ~version=currentSchemaVersion,
      ~timestamp,
      ~projectData,
    )

    let _ =
      set(key, payload)
      ->Promise.then(_ => {
        Logger.debug(
          ~module_="Persistence",
          ~message="Auto-saved session via IndexedDB",
          ~data={
            "timestamp": timestamp,
            "scenes": Array.length(state.scenes),
            "version": currentSchemaVersion,
          },
          (),
        )
        Promise.resolve()
      })
      ->Promise.catch(e => {
        Logger.error(~module_="Persistence", ~message="Auto-save failed", ~data={"error": e}, ())
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: SystemEvent("persistence"),
          message: "Auto-save failed! Please backup your data.",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        Promise.resolve()
      })
  }
}

let handleStateChange = (state: state) => {
  switch lastSaveTimeout.contents {
  | Some(id) => clearTimeout(id)
  | None => ()
  }

  lastSaveTimeout := Some(setTimeout(() => {
        try {
          ignore(requestIdleCallback(() => performSave(state)))
        } catch {
        | _ => performSave(state)
        }
      }, debounceMs))
}

let notifyStateChange = (state: state) => handleStateChange(state)

let initSubscriber = (
  ~getState: unit => state,
  ~onChange: state => unit,
  ~subscribe: (state => unit) => unit => unit,
) => {
  Logger.info(~module_="Persistence", ~message="Initializing Persistence Layer", ())

  stateGetterRef := getState

  beforeUnloadListener.contents->Option.forEach(listener =>
    DomBindings.Window.removeEventListener("beforeunload", listener)
  )

  let listener = _event => {
    switch lastSaveTimeout.contents {
    | Some(_) => performSave(stateGetterRef.contents())
    | None => ()
    }
  }

  beforeUnloadListener := Some(listener)
  DomBindings.Window.addEventListener("beforeunload", listener)

  subscriberRef.contents->Option.forEach(f => f())
  subscriberRef := Some(subscribe(onChange))
}

let clearSession = () => {
  let _ = del(key)
}

let checkRecovery = () => {
  Logger.info(~module_="Persistence", ~message="CHECK_RECOVERY_START", ())
  get(key)->Promise.then(item => {
    Logger.info(~module_="Persistence", ~message="CHECK_RECOVERY_GOT_ITEM", ())
    switch Nullable.toOption(item) {
    | Some(raw) =>
      let json = asJson(raw)
      switch JsonCombinators.Json.decode(json, JsonParsers.Domain.persistedSession) {
      | Ok(savedEnvelope) =>
        if savedEnvelope.version > currentSchemaVersion {
          Logger.warn(
            ~module_="Persistence",
            ~message="Autosave schema is newer than supported",
            ~data={"version": savedEnvelope.version, "supported": currentSchemaVersion},
            (),
          )
          Promise.resolve(None)
        } else {
          switch normalizeProjectData(savedEnvelope.projectData) {
          | Some(normalizedProjectData) =>
            let migrated: serializedSession = {
              version: currentSchemaVersion,
              timestamp: savedEnvelope.timestamp,
              projectData: normalizedProjectData,
            }
            Promise.resolve(Some(migrated))
          | None => Promise.resolve(None)
          }
        }
      | Error(e) => {
          Logger.warn(
            ~module_="Persistence",
            ~message="Corrupt autosave found (decode failed)",
            ~data={"error": e},
            (),
          )
          Promise.resolve(None)
        }
      }
    | None => Promise.resolve(None)
    }
  })
}
