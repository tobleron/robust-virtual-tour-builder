open ReBindings

@scope(("window", "location")) @val external reload: unit => unit = "reload"

let useTourNameSync = (sceneSlice: AppContext.sceneSlice, dispatch: AppContext.dispatch) => {
  let (localTourName, setLocalTourName) = React.useState(() => sceneSlice.tourName)
  let expectedTourName = React.useRef(sceneSlice.tourName)

  React.useEffect2(() => {
    let actual = sceneSlice.tourName
    let local = localTourName
    let expected = expectedTourName.current

    if local == expected && actual != expected {
      Logger.debug(
        ~module_="Sidebar",
        ~message="SYNC_TOUR_NAME_FROM_STATE",
        ~data=Some({"actual": actual, "local": local, "expected": expected}),
        (),
      )
      setLocalTourName(_ => actual)
      expectedTourName.current = actual
    }
    None
  }, (sceneSlice.tourName, localTourName))

  React.useEffect1(() => {
    let timerId = ReBindings.Window.setTimeout(() => {
      if localTourName != sceneSlice.tourName {
        expectedTourName.current = localTourName
        dispatch(Actions.SetTourName(localTourName))
      }
    }, 300)
    Some(() => ReBindings.Window.clearTimeout(timerId))
  }, [localTourName])

  (localTourName, setLocalTourName)
}

let useProcessingState = (fileInputRef: React.ref<Nullable.t<Dom.element>>) => {
  let ops = OperationLifecycle.useOperations()

  let isCriticalProgressType = (type_: OperationLifecycle.operationType) =>
    switch type_ {
    | Upload
    | Teaser
    | Export
    | ProjectLoad
    | ProjectSave => true
    | Navigation
    | Simulation
    | ThumbnailGeneration
    | SceneLoad
    | Unknown(_) => false
    }

  // Find active operation to display
  // Priority: Blocking > Ambient (latest started)
  let activeOp = React.useMemo1(() => {
    let relevantOps = ops->Belt.Array.keep(t => {
      let statusEligible = switch t.status {
      | Active(_) | Paused => true
      | Idle | Completed(_) | Failed(_) | Cancelled => false
      }
      statusEligible && isCriticalProgressType(t.type_)
    })

    let blocking =
      relevantOps
      ->Belt.Array.keep(t => t.scope == Blocking)
      ->Belt.SortArray.stableSortBy((a, b) => compare(b.startedAt, a.startedAt))
      ->Belt.Array.get(0)

    switch blocking {
    | Some(op) => Some(op)
    | None =>
      relevantOps
      ->Belt.Array.keep(t => t.scope == Ambient)
      ->Belt.SortArray.stableSortBy((a, b) => compare(b.startedAt, a.startedAt))
      ->Belt.Array.get(0)
    }
  }, [ops])

  let activeOpRef = React.useRef(activeOp)
  React.useEffect1(() => {
    activeOpRef.current = activeOp
    None
  }, [activeOp])

  let (procState, setProcState) = React.useState(_ =>
    {
      "active": false,
      "progress": 0.0,
      "message": "",
      "phase": "",
      "error": false,
      "onCancel": () => (),
      "cancellable": false,
      "eta": (None: option<string>),
    }
  )

  // Ref to track if we should hide
  let isVisible = React.useRef(false)
  let visibilityTimer = React.useRef(None)
  let (forceUpdate, setForceUpdate) = React.useState(_ => 0)

  React.useEffect2(() => {
    // Clear previous timer
    visibilityTimer.current->Option.forEach(id => ReBindings.Window.clearTimeout(id))
    visibilityTimer.current = None

    switch activeOp {
    | Some(op) =>
      let now = Date.now()
      let elapsed = now -. op.startedAt
      let threshold = op.visibleAfterMs->Int.toFloat

      let shouldBeVisible = switch op.status {
      | Failed(_) => true
      | Completed(_) =>
        // Only show completed if it ran longer than threshold
        let duration = op.updatedAt -. op.startedAt
        duration >= threshold
      | Active(_) | Paused => elapsed >= threshold
      | Cancelled | Idle => false
      }

      // Schedule visibility check if active but not yet visible
      if !shouldBeVisible {
        switch op.status {
        | Active(_) | Paused =>
          let remaining = threshold -. elapsed
          if remaining > 0.0 {
            let id = ReBindings.Window.setTimeout(() => {
              setForceUpdate(prev => prev + 1)
            }, remaining->Float.toInt + 10)
            visibilityTimer.current = Some(id)
          }
        | _ => ()
        }
      }

      if shouldBeVisible {
        let (progress, message, error, active) = switch op.status {
        | Active({progress, message}) => (progress, message->Option.getOr(""), false, true)
        | Paused => (0.0, "Paused", false, true)
        | Completed({result}) => (100.0, result->Option.getOr("Done"), false, true)
        | Failed({error}) => (0.0, error, true, true)
        | Cancelled => (0.0, "Cancelled", false, false)
        | Idle => (0.0, "", false, false)
        }

        if op.status == Cancelled {
          setProcState(prev => {
            let next = Object.assign(Object.make(), prev)
            next["active"] = false
            next
          })
          isVisible.current = false
        } else {
          setProcState(prev => {
            let newState = {
              "active": active,
              "progress": progress,
              "message": message,
              "phase": op.phase,
              "error": error,
              "onCancel": () => OperationLifecycle.cancel(op.id),
              "cancellable": op.cancellable,
              "eta": prev["eta"], // Preserve ETA from legacy events if any
            }
            newState
          })
          isVisible.current = active
        }
      } // Hide if currently visible
      else if isVisible.current {
        setProcState(prev => {
          let next = Object.assign(Object.make(), prev)
          next["active"] = false
          next
        })
        isVisible.current = false
      }

    | None =>
      // Only hide if we were visible
      if isVisible.current {
        setProcState(prev => {
          let next = Object.assign(Object.make(), prev)
          next["active"] = false
          next
        })
        isVisible.current = false
      }
    }

    Some(
      () => {
        visibilityTimer.current->Option.forEach(id => ReBindings.Window.clearTimeout(id))
      },
    )
  }, (activeOp, forceUpdate))

  React.useEffect0(() => {
    Logger.initialized(~module_="Sidebar")

    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | TriggerUpload =>
        switch Nullable.toOption(fileInputRef.current) {
        | Some(el) => ReBindings.Dom.click(el)
        | None => ()
        }
      | CancelActiveOperation =>
        // ESC key or any system-level cancel — invoke the active operation's abort
        Logger.info(~module_="Sidebar", ~message="CANCEL_ACTIVE_OPERATION_VIA_ESC", ())
        switch activeOpRef.current {
        | Some(op) => OperationLifecycle.cancel(op.id)
        | None => ()
        }
      | UpdateProcessing(payload) =>
        // Only update if no active OperationLifecycle op (to support legacy calls if any)
        // Or handle mixing? If OperationLifecycle is active, ignore legacy updates?
        // Since we migrated major flows, most should come via OperationLifecycle.
        // But UploadProcessor updates come via UpdateProcessing AND OperationLifecycle.
        // OperationLifecycle is preferred.

        switch activeOpRef.current {
        | Some(_) =>
          // Update ETA even if activeOp exists, as it's not in Lifecycle yet
          setProcState(
            prev => {
              let next = Object.assign(Object.make(), prev)
              next["eta"] = payload["eta"]
              next["message"] = payload["message"]
              next
            },
          )
        | None =>
          // Legacy fallback safety:
          // ignore late "active=true" payloads when there is no active lifecycle operation.
          // This prevents stale callbacks from resurrecting an endless progress UI.
          if payload["active"] {
            Logger.debug(
              ~module_="Sidebar",
              ~message="IGNORING_STALE_LEGACY_PROCESSING_UPDATE",
              ~data=Some({"message": payload["message"], "phase": payload["phase"]}),
              (),
            )
          } else {
            // Allow inactive payload to force clear.
            setProcState(
              _ =>
                {
                  "active": false,
                  "progress": payload["progress"],
                  "message": payload["message"],
                  "phase": payload["phase"],
                  "error": payload["error"],
                  "onCancel": payload["onCancel"],
                  "cancellable": false,
                  "eta": payload["eta"],
                },
            )
          }
        }
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  procState
}

let localAssetCount = (state: Types.state): int => {
  let sceneAssets =
    SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    ->Belt.Array.keep(scene =>
      switch scene.file {
      | File(_) | Blob(_) => true
      | Url(_) => false
      }
    )
    ->Belt.Array.length
  let logoAssets = switch state.logo {
  | Some(File(_)) | Some(Blob(_)) => 1
  | _ => 0
  }
  sceneAssets + logoAssets
}

let saveToServer = async (~state, ~dispatch, ~onPhase: option<string => unit>=?) => {
  let projectData = ProjectSystem.encodeProjectFromState(state)
  let snapshotResult = switch state.sessionId {
  | Some(id) => await Api.ProjectApi.syncSnapshot(~sessionId=id, ~projectData, ~origin=Manual)
  | None => await Api.ProjectApi.syncSnapshot(~projectData, ~origin=Manual)
  }

  switch snapshotResult {
  | Ok(syncResult) =>
    if state.sessionId == None {
      dispatch(Actions.SetSessionId(syncResult.sessionId))
    }
    let assetsToSync = localAssetCount(state)
    if assetsToSync > 0 {
      switch onPhase {
      | Some(notify) => notify("Uploading " ++ Belt.Int.toString(assetsToSync) ++ " assets...")
      | None => ()
      }
      let assetResult = await Api.ProjectApi.syncSnapshotAssets(~sessionId=syncResult.sessionId, ~state)
      switch assetResult {
      | Ok(_) => true
      | Error(msg) =>
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_save_server"),
          message: "Server save failed while uploading assets",
          details: Some(msg),
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        false
      }
    } else {
      true
    }
  | Error(msg) =>
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("sidebar_save_server"),
      message: "Server save failed",
      details: Some(msg),
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    false
  }
}

let handleSave = async (~mode, ~getState, ~signal, ~onCancel, ~dispatch) => {
  let opIdRef = ref(None)

  try {
    let state: Types.state = getState()
    // Start OperationLifecycle
    let opId = OperationLifecycle.start(
      ~type_=ProjectSave,
      ~scope=Blocking,
      ~phase="Initializing",
      ~meta=Logger.castToJson({
        "sceneCount": Array.length(
          SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
        ),
      }),
      (),
    )
    opIdRef := Some(opId)
    OperationLifecycle.registerCancel(opId, onCancel)

    let success = switch mode {
    | PersistencePreferences.Offline =>
      await ProjectManager.saveProject(
        state,
        ~signal,
        ~onProgress=(pct, _t, msg) => {
          SidebarLogic.updateProgress(~dispatch, ~onCancel, pct->Int.toFloat, msg, true, "Save")
        },
        ~opId,
      )
    | PersistencePreferences.Server =>
      SidebarLogic.updateProgress(~dispatch, ~onCancel, 10.0, "Saving metadata...", true, "Save")
      OperationLifecycle.progress(opId, 15.0, ~message="Saving metadata...", ~phase="Save", ())
      let assets = localAssetCount(state)
      let success = await saveToServer(
        ~state,
        ~dispatch,
        ~onPhase=message => {
          SidebarLogic.updateProgress(~dispatch, ~onCancel, 70.0, message, true, "Save")
          OperationLifecycle.progress(opId, 70.0, ~message, ~phase="Uploading", ())
        },
      )
      if success {
        let finalMessage =
          if assets > 0 {
            "Server snapshot saved with assets"
          } else {
            "Server snapshot saved"
          }
        OperationLifecycle.complete(opId, ~result=finalMessage, ())
      } else {
        OperationLifecycle.fail(opId, "Server save failed")
      }
      success
    | PersistencePreferences.Both =>
      SidebarLogic.updateProgress(~dispatch, ~onCancel, 10.0, "Saving metadata...", true, "Save")
      OperationLifecycle.progress(opId, 15.0, ~message="Saving metadata...", ~phase="Save", ())
      let serverSuccess = await saveToServer(
        ~state,
        ~dispatch,
        ~onPhase=message => {
          SidebarLogic.updateProgress(~dispatch, ~onCancel, 45.0, message, true, "Save")
          OperationLifecycle.progress(opId, 45.0, ~message, ~phase="Uploading", ())
        },
      )
      if serverSuccess {
        SidebarLogic.updateProgress(~dispatch, ~onCancel, 55.0, "Creating offline package...", true, "Save")
        await ProjectManager.saveProject(
          state,
          ~signal,
          ~onProgress=(pct, _t, msg) => {
            let adjusted = 55.0 +. (pct->Int.toFloat *. 0.45)
            SidebarLogic.updateProgress(~dispatch, ~onCancel, adjusted, msg, true, "Save")
          },
          ~opId,
        )
      } else {
        false
      }
    }

    if success {
      let successLabel = switch mode {
      | PersistencePreferences.Offline => "Offline save complete"
      | PersistencePreferences.Server => "Server save complete"
      | PersistencePreferences.Both => "Server and offline save complete"
      }
      SidebarLogic.updateProgress(~dispatch, 100.0, successLabel, false, "")
      NotificationManager.dispatch({
        id: "",
        importance: Success,
        context: Operation("sidebar_save"),
        message: successLabel,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Success),
        dismissible: true,
        createdAt: Date.now(),
      })
    } // Check if it was cancelled via signal
    else if BrowserBindings.AbortSignal.aborted(signal) {
      SidebarLogic.updateProgress(~dispatch, 0.0, "Cancelled", false, "")

      NotificationManager.dispatch({
        id: "save-cancelled-notification",
        importance: Info,
        context: Operation("sidebar_save"),
        message: "Save Cancelled",
        details: None,
        action: None,
        duration: 5000,
        dismissible: true,
        createdAt: Date.now(),
      })
    } else {
      SidebarLogic.updateProgress(~dispatch, 0.0, "Save Failed", false, "")
    }
  } catch {
  | exn => {
      let (msg, _) = Logger.getErrorDetails(exn)
      SidebarLogic.updateProgress(~dispatch, 0.0, "Error", false, "")

      opIdRef.contents->Option.forEach(id => OperationLifecycle.fail(id, msg))

      NotificationManager.dispatch({
        id: "",
        importance: Error,
        context: Operation("sidebar_save"),
        message: "Save failed: " ++ msg,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
    }
  }
}
