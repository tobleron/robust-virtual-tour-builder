/* src/utils/PersistenceLayer.res */

open IdbBindings

type serializedSession = {
  timestamp: float,
  projectData: JSON.t,
}

let key = "autosave_session_latest"
let debounceMs = 2000

@val external requestIdleCallback: (unit => unit) => int = "requestIdleCallback"
@val external cancelIdleCallback: int => unit = "cancelIdleCallback"

external asJson: unknown => JSON.t = "%identity"

let lastSaveTimeout = ref(None)
let lastQuotaCheck = ref(0.0)
let quotaCheckInterval = 60000.0 // 1 minute

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

    let payload = {
      timestamp: Date.now(),
      projectData,
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

        // Throttled quota check
        let now = Date.now()
        if now -. lastQuotaCheck.contents > quotaCheckInterval {
          lastQuotaCheck := now
          ignore(QuotaMonitor.checkQuota())
        }

        Promise.resolve()
      })
      ->Promise.catch(e => {
        let (msg, _) = Logger.getErrorDetails(e)
        Logger.error(~module_="Persistence", ~message="Auto-save failed", ~data={"error": msg}, ())

        let message = if String.includes(msg, "QuotaExceeded") {
          "Save failed: Storage full. Please free space by deleting old projects."
        } else {
          "Auto-save failed! Please backup your data."
        }

        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: SystemEvent("persistence"),
          message,
          details: Some(msg),
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
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

let unsub = ref(None)

let initSubscriber = () => {
  /* We subscribe to the GlobalStateBridge to detect changes */
  Logger.info(~module_="Persistence", ~message="Initializing Persistence Layer", ())

  // Initial quota check
  ignore(QuotaMonitor.checkQuota())

  unsub.contents->Option.forEach(f => f())
  unsub := Some(GlobalStateBridge.subscribe(onStateChange))

  DomBindings.Window.addEventListener("beforeunload", _ => {
    switch lastSaveTimeout.contents {
    | Some(_) =>
      let _ = performSave(GlobalStateBridge.getState())
    | None => ()
    }
  })
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
      let decoder = JsonCombinators.Json.Decode.object(field => {
        {
          timestamp: field.required("timestamp", JsonCombinators.Json.Decode.float),
          projectData: field.required("projectData", JsonCombinators.Json.Decode.id),
        }
      })

      switch JsonCombinators.Json.decode(json, decoder) {
      | Ok(saved) => Promise.resolve(Some(saved))
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
