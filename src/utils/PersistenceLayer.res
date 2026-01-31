@@warning("-3")
/* src/utils/PersistenceLayer.res */

open IdbBindings

type serializedSession = {
  timestamp: float,
  projectData: JSON.t,
}

// Schema removed to satisfy CSP (no eval).
// Replaced with direct casting for internal persistence.

let key = "autosave_session_latest"
let debounceMs = 2000

@val external requestIdleCallback: (unit => unit) => int = "requestIdleCallback"
@val external cancelIdleCallback: int => unit = "cancelIdleCallback"

external asJson: unknown => JSON.t = "%identity"

let lastSaveTimeout = ref(None)

let performSave = (state: Types.state) => {
  /* Only save if we have scenes or a project name that differs from default */
  let hasContent = Array.length(state.scenes) > 0 || state.tourName != "Tour Name"

  if hasContent {
    let project: Types.project = {
      tourName: state.tourName,
      scenes: state.scenes,
      lastUsedCategory: state.lastUsedCategory,
      exifReport: state.exifReport,
      sessionId: state.sessionId,
      deletedSceneIds: state.deletedSceneIds,
      timeline: state.timeline,
    }

    // CSP SAFE FIX: Direct cast since Record = JS Object in ReScript v11+. Schema uses eval.
    let projectData = Obj.magic(project)

    let payload = {
      timestamp: Date.now(),
      projectData: asJson(projectData),
    }

    let _ =
      set(key, payload)
      ->Promise.then(_ => {
        Logger.debug(
          ~module_="Persistence",
          ~message="Auto-saved session via IndexedDB",
          ~data={"timestamp": payload.timestamp, "scenes": Array.length(state.scenes)},
          (),
        )
        Promise.resolve()
      })
      ->Promise.catch(e => {
        Logger.error(~module_="Persistence", ~message="Auto-save failed", ~data={"error": e}, ())
        Promise.resolve()
      })
  }
}

let onStateChange = (state: Types.state) => {
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

let initSubscriber = () => {
  /* We subscribe to the GlobalStateBridge to detect changes */
  Logger.info(~module_="Persistence", ~message="Initializing Persistence Layer", ())
  let _ = GlobalStateBridge.subscribe(onStateChange)
}

let clearSession = () => {
  let _ = del(key)
}

let checkRecovery = () => {
  get(key)->Promise.then(item => {
    switch Nullable.toOption(item) {
    | Some(raw) =>
      try {
        // CSP SAFE FIX: Casting instead of schema validation
        let saved: serializedSession = Obj.magic(raw)
        Promise.resolve(Some(saved))
      } catch {
      | Js.Exn.Error(e) =>
        Logger.warn(
          ~module_="Persistence",
          ~message="Corrupt autosave found (cast failed)",
          ~data={"error": Js.Exn.message(e)},
          (),
        )
        Promise.resolve(None)
      | _ => Promise.resolve(None)
      }
    | None => Promise.resolve(None)
    }
  })
}
