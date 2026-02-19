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
  let (procState, setProcState) = React.useState(_ =>
    {
      "active": false,
      "progress": 0.0,
      "message": "",
      "phase": "",
      "error": false,
      "onCancel": () => (),
    }
  )

  let appearanceTimerRef = React.useRef(Nullable.null)
  let hideTimerRef = React.useRef(Nullable.null)
  let isBarVisible = React.useRef(false)
  // Tracks the latest cancel callback so ESC (CancelActiveOperation) can abort any running op.
  let currentCancelRef = React.useRef(() => ())

  React.useEffect0(() => {
    Logger.initialized(~module_="Sidebar")

    let unsubscribe = EventBus.subscribe(event => {
      switch event {
      | TriggerUpload =>
        switch Nullable.toOption(fileInputRef.current) {
        | Some(el) => ReBindings.Dom.click(el)
        | None => ()
        }
      | UpdateProcessing(payload) => {
          let wantedActive = payload["active"]

          if wantedActive {
            // Track the latest cancel callback for ESC support
            currentCancelRef.current = payload["onCancel"]

            // Cancel any pending hide
            switch Nullable.toOption(hideTimerRef.current) {
            | Some(timerId) =>
              ReBindings.Window.clearTimeout(timerId)
              hideTimerRef.current = Nullable.null
            | None => ()
            }

            if isBarVisible.current {
              // Already showing, just update
              setProcState(_ => payload)
            } else if Nullable.isNullable(appearanceTimerRef.current) {
              // Not showing, and no timer? Start appearance delay.
              let tid = ReBindings.Window.setTimeout(
                () => {
                  setProcState(_ => payload)
                  isBarVisible.current = true
                  appearanceTimerRef.current = Nullable.null
                },
                1000,
              )
              appearanceTimerRef.current = Nullable.fromOption(Some(tid))
            }
          } else {
            // Operation is finished (Inactive) — clear the cancel ref
            currentCancelRef.current = () => ()

            // 1. Cancel any pending appearance
            switch Nullable.toOption(appearanceTimerRef.current) {
            | Some(tid) =>
              ReBindings.Window.clearTimeout(tid)
              appearanceTimerRef.current = Nullable.null
            | None => ()
            }

            // 2. Cancel any pending hide
            switch Nullable.toOption(hideTimerRef.current) {
            | Some(tid) =>
              ReBindings.Window.clearTimeout(tid)
              hideTimerRef.current = Nullable.null
            | None => ()
            }

            if payload["progress"] >= 100.0 && isBarVisible.current {
              // Done and visible: Victory Lap (Hold 1500ms)
              setProcState(_ => payload)
              let tid = ReBindings.Window.setTimeout(
                () => {
                  setProcState(
                    prev => {
                      let next = Object.assign(Object.make(), prev)
                      next["active"] = false
                      next
                    },
                  )
                  isBarVisible.current = false
                  hideTimerRef.current = Nullable.null
                },
                1500,
              )
              hideTimerRef.current = Nullable.fromOption(Some(tid))
            } else {
              // Error, Cancelled, or was never visible: Instant hide/stay hidden
              setProcState(_ => payload)
              isBarVisible.current = false
            }
          }
        }
      | CancelActiveOperation =>
        // ESC key or any system-level cancel — invoke the active operation's abort
        Logger.info(~module_="Sidebar", ~message="CANCEL_ACTIVE_OPERATION_VIA_ESC", ())
        currentCancelRef.current()
      | _ => ()
      }
    })
    Some(unsubscribe)
  })

  procState
}

let handleSave = async (~getState, ~signal, ~onCancel, ~dispatch) => {
  try {
    let state = getState()
    let success = await ProjectManager.saveProject(state, ~signal, ~onProgress=(pct, _t, msg) => {
      SidebarLogic.updateProgress(~dispatch, ~onCancel, pct->Int.toFloat, msg, true, "Save")
    })

    if success {
      SidebarLogic.updateProgress(~dispatch, 100.0, "Saved", false, "")
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
    }
  } catch {
  | exn => {
      let (msg, _) = Logger.getErrorDetails(exn)
      SidebarLogic.updateProgress(~dispatch, 0.0, "Error", false, "")
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
