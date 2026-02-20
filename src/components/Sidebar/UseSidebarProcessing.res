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

  // Find active operation to display
  // Priority: Blocking > Ambient (latest started)
  let activeOp = React.useMemo1(() => {
    let relevantOps = ops->Belt.Array.keep(t => {
      switch t.status {
      | Active(_) | Paused | Completed(_) | Failed(_) | Cancelled => true
      | Idle => false
      }
    })

    let blocking = relevantOps
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
    }
  )

  // Ref to track if we should hide
  let isVisible = React.useRef(false)

  React.useEffect1(() => {
    switch activeOp {
    | Some(op) =>
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
         let newState = {
            "active": active,
            "progress": progress,
            "message": message,
            "phase": op.phase,
            "error": error,
            "onCancel": () => OperationLifecycle.cancel(op.id),
            "cancellable": op.cancellable,
         }
         setProcState(_ => newState)
         isVisible.current = active
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
    None
  }, [activeOp])

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
        | Some(_) => () // Ignore if activeOp exists
        | None =>
           // Map legacy payload
           let cancellable = true // Assume legacy is cancellable if active
           setProcState(_ => {
             "active": payload["active"],
             "progress": payload["progress"],
             "message": payload["message"],
             "phase": payload["phase"],
             "error": payload["error"],
             "onCancel": payload["onCancel"],
             "cancellable": cancellable,
           })
        }
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  procState
}

let handleSave = async (~getState, ~signal, ~onCancel, ~dispatch) => {
  let opIdRef = ref(None)

  try {
    let state = getState()
    // Start OperationLifecycle
    let opId = OperationLifecycle.start(
       ~type_=ProjectSave,
       ~scope=Blocking,
       ~phase="Initializing",
       ~meta=Some(Logger.castToJson({"sceneCount": Array.length(state.scenes)})),
       (),
    )
    opIdRef := Some(opId)
    OperationLifecycle.registerCancel(opId, onCancel)

    let success = await ProjectManager.saveProject(state, ~signal, ~onProgress=(pct, _t, msg) => {
      SidebarLogic.updateProgress(~dispatch, ~onCancel, pct->Int.toFloat, msg, true, "Save")
    }, ~opId)

    if success {
      SidebarLogic.updateProgress(~dispatch, 100.0, "Saved", false, "")
      // OperationLifecycle.complete handled by createSavePackage
      NotificationManager.dispatch({
        id: "",
        importance: Success,
        context: Operation("sidebar_save"),
        message: "Project saved successfully",
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
      // OperationLifecycle.fail handled by createSavePackage
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
