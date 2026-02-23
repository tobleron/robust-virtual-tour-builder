/* src/components/Sidebar/SidebarLogicHandler.res */

open SidebarBase
open ReBindings

@get external value: 'a => string = "value"
@set external set_value: ('a, string) => unit = "value"

let uploadProgressToastId = "sidebar-upload-progress"
let exportProgressToastId = "sidebar-export-progress"

type etaRuntimeMetrics = {
  completed: int,
  total: int,
  inFlightUtilization: option<float>,
}

type exportRuntimeMetrics = {
  packagedScene: option<(int, int)>,
  uploadedMb: option<(float, float)>,
}

let parseProcessingMetrics = (msg: string): option<etaRuntimeMetrics> => {
  let primary =
    msg
    ->String.split("|")
    ->Belt.Array.get(0)
    ->Option.getOr("")
    ->String.trim

  if !String.startsWith(primary, "Processing ") {
    None
  } else {
    let countToken = primary->String.split(" ")->Belt.Array.get(1)->Option.getOr("")
    let countParts = countToken->String.split("/")

    switch (
      countParts->Belt.Array.get(0)->Option.flatMap(Belt.Int.fromString),
      countParts->Belt.Array.get(1)->Option.flatMap(Belt.Int.fromString),
    ) {
    | (Some(completed), Some(total)) if total > 0 =>
      let inFlightUtilization =
        msg
        ->String.split("In-flight:")
        ->Belt.Array.get(1)
        ->Option.flatMap(raw => {
          let pair =
            raw
            ->String.split("MB")
            ->Belt.Array.get(0)
            ->Option.getOr("")
            ->String.trim
          let vals = pair->String.split("/")
          switch (
            vals->Belt.Array.get(0)->Option.flatMap(Belt.Float.fromString),
            vals->Belt.Array.get(1)->Option.flatMap(Belt.Float.fromString),
          ) {
          | (Some(current), Some(max)) if max > 0.0 => Some(current /. max)
          | _ => None
          }
        })
      Some({completed, total, inFlightUtilization})
    | _ => None
    }
  }
}

let parseExportMetrics = (msg: string): exportRuntimeMetrics => {
  let primary =
    msg
    ->String.split("|")
    ->Belt.Array.get(0)
    ->Option.getOr("")
    ->String.trim

  let packagedScene = if String.startsWith(primary, "Packaging scene ") {
    let sceneWord = primary->String.split("scene ")->Belt.Array.get(1)->Option.getOr("")
    let pair = sceneWord->String.split(" of ")
    switch (
      pair->Belt.Array.get(0)->Option.flatMap(Belt.Int.fromString),
      pair
      ->Belt.Array.get(1)
      ->Option.flatMap(raw =>
        raw
        ->String.split(".")
        ->Belt.Array.get(0)
        ->Option.getOr(raw)
        ->Belt.Int.fromString
      ),
    ) {
    | (Some(completed), Some(total)) if total > 0 => Some((completed, total))
    | _ => None
    }
  } else {
    None
  }

  let uploadedMb = if String.startsWith(primary, "Uploading: ") {
    let sentWord = primary->String.split("Uploading: ")->Belt.Array.get(1)->Option.getOr("")
    let pair = sentWord->String.split(" of ")
    switch (
      pair->Belt.Array.get(0)->Option.flatMap(Belt.Float.fromString),
      pair
      ->Belt.Array.get(1)
      ->Option.flatMap(raw =>
        raw
        ->String.split(" ")
        ->Belt.Array.get(0)
        ->Option.getOr(raw)
        ->Belt.Float.fromString
      ),
    ) {
    | (Some(sent), Some(total)) if total > 0.0 => Some((sent, total))
    | _ => None
    }
  } else {
    None
  }

  {packagedScene, uploadedMb}
}

let performUpload = async (
  files,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let fileArray = JsHelpers.from(files)
  let startedAtMs = Date.now()
  let lastEtaToastAtMs = ref(0.0)
  let knownTotalItems = ref(Belt.Array.length(fileArray))
  let lastPctSample = ref(0.0)
  let lastSampleAtMs = ref(startedAtMs)
  let emaProgressPerSecond = ref(0.0)
  let lastCompletedSample = ref(0)
  let lastCompletedAtMs = ref(startedAtMs)
  let emaSecondsPerItem = ref(0.0)
  let completionSampleCount = ref(0)
  let stableEtaSeconds = ref(0.0)
  let etaReady = ref(false)
  let wasCancelled = ref(false)
  let cancelToastSent = ref(false)

  try {
    let result: UploadTypes.processResult = await UploadProcessor.processUploads(
      fileArray,
      Some(
        (pct, msg, isProc, phase) => {
          if phase == "Cancelled" || String.startsWith(msg, "Cancelled") {
            wasCancelled := true
          }
          updateProgress(~dispatch, pct, msg, isProc, phase)
          if isProc && pct > 0.0 && pct < 100.0 {
            let now = Date.now()
            let parsedMetrics = parseProcessingMetrics(msg)

            parsedMetrics->Option.forEach(m => {
              knownTotalItems := m.total
              if m.completed > lastCompletedSample.contents {
                let deltaItems = m.completed - lastCompletedSample.contents
                let deltaSeconds = (now -. lastCompletedAtMs.contents) /. 1000.0
                if deltaItems > 0 && deltaSeconds > 0.4 {
                  let instSecondsPerItem = deltaSeconds /. Belt.Int.toFloat(deltaItems)
                  if emaSecondsPerItem.contents <= 0.0 {
                    emaSecondsPerItem := instSecondsPerItem
                  } else {
                    emaSecondsPerItem :=
                      0.75 *. emaSecondsPerItem.contents +. 0.25 *. instSecondsPerItem
                  }
                  completionSampleCount := completionSampleCount.contents + 1
                }
                lastCompletedSample := m.completed
                lastCompletedAtMs := now
              }
            })

            let deltaPct = pct -. lastPctSample.contents
            let deltaSec = (now -. lastSampleAtMs.contents) /. 1000.0
            if deltaPct > 0.0 && deltaSec > 0.4 {
              let instRate = deltaPct /. deltaSec
              if emaProgressPerSecond.contents <= 0.0 {
                emaProgressPerSecond := instRate
              } else {
                // Smooth sudden jumps from early-stage pipeline transitions.
                emaProgressPerSecond := 0.8 *. emaProgressPerSecond.contents +. 0.2 *. instRate
              }
              lastPctSample := pct
              lastSampleAtMs := now
            }

            let elapsedSec = (now -. startedAtMs) /. 1000.0
            if (
              !etaReady.contents &&
              completionSampleCount.contents >= 2 &&
              elapsedSec >= 25.0 &&
              pct >= 20.0 &&
              emaProgressPerSecond.contents > 0.0
            ) {
              etaReady := true
            }

            let shouldUpdateToast = now -. lastEtaToastAtMs.contents >= 1500.0
            if shouldUpdateToast {
              let processedItems = lastCompletedSample.contents
              let totalItems = knownTotalItems.contents
              let remainingItems = if totalItems > processedItems {
                totalItems - processedItems
              } else {
                0
              }

              let etaByRecentItemRate = if emaSecondsPerItem.contents > 0.0 && remainingItems > 0 {
                Some(emaSecondsPerItem.contents *. Belt.Int.toFloat(remainingItems))
              } else {
                None
              }
              let etaByGlobalItemAverage = if processedItems >= 1 && remainingItems > 0 {
                let avgSecPerItem = elapsedSec /. Belt.Int.toFloat(processedItems)
                Some(avgSecPerItem *. Belt.Int.toFloat(remainingItems))
              } else {
                None
              }
              let etaByProgressSlope = if emaProgressPerSecond.contents > 0.0 {
                Some((100.0 -. pct) /. emaProgressPerSecond.contents)
              } else {
                None
              }

              let blendedEta = EtaSupport.combineEtaCandidates(
                ~a=etaByRecentItemRate,
                ~b=etaByGlobalItemAverage,
                ~c=etaByProgressSlope,
              )->Option.map(raw => {
                let utilizationFactor = switch parsedMetrics {
                | Some(m) =>
                  // A small utilization-based correction inferred from in-flight pressure.
                  m.inFlightUtilization
                  ->Option.map(
                    u =>
                      0.95 +. 0.15 *. EtaSupport.clampFloat(~value=u, ~minValue=0.0, ~maxValue=1.0),
                  )
                  ->Option.getOr(1.0)
                | None => 1.0
                }
                raw *. utilizationFactor
              })

              let etaSeconds = switch blendedEta {
              | Some(candidate) if etaReady.contents =>
                let smoothed = if stableEtaSeconds.contents <= 0.0 {
                  candidate
                } else {
                  let raw = 0.78 *. stableEtaSeconds.contents +. 0.22 *. candidate
                  // Bound step changes to avoid jarring jumps in user-facing ETA.
                  let maxRise = stableEtaSeconds.contents +. 30.0
                  let maxDrop = stableEtaSeconds.contents -. 20.0
                  EtaSupport.clampFloat(
                    ~value=raw,
                    ~minValue=Math.max(1.0, maxDrop),
                    ~maxValue=maxRise,
                  )
                }
                stableEtaSeconds := smoothed
                Belt.Float.toInt(smoothed)
              | _ => 0
              }

              lastEtaToastAtMs := now
              if etaReady.contents {
                EtaSupport.dispatchEtaToast(
                  ~id=uploadProgressToastId,
                  ~contextOperation="eta_upload",
                  ~prefix="Uploading",
                  ~etaSeconds,
                  ~details=Some(phase ++ " • " ++ msg),
                  ~createdAt=now,
                  (),
                )
              } else {
                EtaSupport.dispatchCalculatingEtaToast(
                  ~id=uploadProgressToastId,
                  ~contextOperation="eta_upload",
                  ~prefix="Uploading",
                  ~details=Some(phase ++ " • " ++ msg),
                  ~createdAt=now,
                  (),
                )
              }
            }
          }
        },
      ),
      ~getState,
      ~dispatch,
      ~onCancel=() => {
        wasCancelled := true
        NotificationManager.dismiss(uploadProgressToastId)
        updateProgress(~dispatch, 0.0, "Cancelled", false, "Cancelled")
        if !cancelToastSent.contents {
          cancelToastSent := true
          NotificationManager.dispatch({
            id: "",
            importance: Info,
            context: Operation("sidebar_upload"),
            message: "Upload cancelled",
            details: None,
            action: None,
            duration: NotificationTypes.defaultTimeoutMs(Info),
            dismissible: true,
            createdAt: Date.now(),
          })
        }
      },
    )

    if wasCancelled.contents {
      NotificationManager.dismiss(uploadProgressToastId)
    } else {
      let qualityResults = result.qualityResults
      let report = result.report
      let successfulCount = Belt.Array.length(report.success)
      let hasAnySuccess = successfulCount > 0

      if hasAnySuccess {
        NotificationManager.dismiss(uploadProgressToastId)
        dispatch(DispatchAppFsmEvent(UploadComplete(report, qualityResults)))
        UploadReport.show(report, qualityResults, ~getState, ~dispatch)
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("sidebar_upload"),
          message: "Upload Complete",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
      } else {
        NotificationManager.dismiss(uploadProgressToastId)
        dispatch(
          Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Upload failed: no files processed")),
        )
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_upload"),
          message: "Upload failed: no files processed",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 100.0, "Upload failed", false, "Error")
      }
    }
  } catch {
  | JsExn(obj) =>
    NotificationManager.dismiss(uploadProgressToastId)
    let msg = switch JsExn.message(obj) {
    | Some(m) => m
    | None => "Unknown error"
    }
    if msg == "CANCELLED" || wasCancelled.contents {
      updateProgress(~dispatch, 0.0, "Cancelled", false, "Cancelled")
      if !cancelToastSent.contents {
        cancelToastSent := true
        NotificationManager.dispatch({
          id: "",
          importance: Info,
          context: Operation("sidebar_upload"),
          message: "Upload cancelled",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Info),
          dismissible: true,
          createdAt: Date.now(),
        })
      }
    } else {
      dispatch(Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Upload Failed: " ++ msg)))
      NotificationManager.dispatch({
        id: "",
        importance: Error,
        context: Operation("sidebar_upload"),
        message: "Upload failed: " ++ msg,
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Error),
        dismissible: true,
        createdAt: Date.now(),
      })
      updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
    }
  | _ => dispatch(Actions.DispatchAppFsmEvent(CriticalErrorOccurred("Unknown Upload Error")))
  }
}

let handleUpload = async (
  filesOpt,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    let state = getState()
    let canUpload = Capability.Policy.evaluate(
      ~capability=CanUpload,
      ~appMode=state.appMode,
      OperationLifecycle.getOperations(),
    )

    if !canUpload {
      NotificationManager.dispatch({
        id: "",
        importance: Warning,
        context: Operation("sidebar_upload"),
        message: "Please wait for current operation to finish",
        details: None,
        action: None,
        duration: NotificationTypes.defaultTimeoutMs(Warning),
        dismissible: true,
        createdAt: Date.now(),
      })
    } else {
      dispatch(DispatchAppFsmEvent(StartUpload))
      EtaSupport.dispatchCalculatingEtaToast(
        ~id=uploadProgressToastId,
        ~contextOperation="eta_upload",
        ~prefix="Uploading",
        (),
      )
      await performUpload(files, ~getState, ~dispatch)
    }
  | _ => ()
  }
}

let handleLoadProject = async (filesOpt, ~getState, ~dispatch, _sceneCount, target) => {
  switch filesOpt {
  | Some(files) if FileList.length(files) > 0 =>
    SessionStore.clearState()
    try {
      switch FileList.item(files, 0) {
      | Some(file) =>
        let controller = BrowserBindings.AbortController.make()
        let signal = BrowserBindings.AbortController.signal(controller)
        let loadSettled = ref(false)
        let timeoutMs = 120000
        let abortRequest = () => BrowserBindings.AbortController.abort(controller)
        let onCancel = () => {
          if !loadSettled.contents {
            loadSettled := true
            updateProgress(~dispatch, 0.0, "Cancelled", false, "")
            dispatch(Actions.DispatchAppFsmEvent(ProjectLoadError("Cancelled")))
            NotificationManager.dispatch({
              id: "",
              importance: Info,
              context: Operation("sidebar_load_project"),
              message: "Project load cancelled",
              details: None,
              action: None,
              duration: NotificationTypes.defaultTimeoutMs(Info),
              dismissible: true,
              createdAt: Date.now(),
            })
          }
          abortRequest()
        }
        dispatch(Actions.DispatchAppFsmEvent(StartProjectLoad({name: File.name(file)})))

        let opId = OperationLifecycle.start(
          ~type_=ProjectLoad,
          ~scope=Blocking,
          ~phase="Loading",
          ~meta=Logger.castToJson({
            "filename": File.name(file),
            "size": File.size(file),
          }),
          (),
        )
        OperationLifecycle.registerCancel(opId, onCancel)

        let finalizeFailure = (msg: string) => {
          if !loadSettled.contents {
            loadSettled := true
            if OperationLifecycle.isActive(opId) {
              OperationLifecycle.fail(opId, msg)
            }
            dispatch(Actions.DispatchAppFsmEvent(ProjectLoadError(msg)))
            NotificationManager.dispatch({
              id: "",
              importance: Error,
              context: Operation("sidebar_load_project"),
              message: "Failed to load project: " ++ msg,
              details: None,
              action: None,
              duration: NotificationTypes.defaultTimeoutMs(Error),
              dismissible: true,
              createdAt: Date.now(),
            })
            updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
            Logger.endOperation(
              ~module_="Sidebar",
              ~operation="PROJECT_LOAD",
              ~data={"success": false, "error": msg},
              (),
            )
          }
        }

        updateProgress(~dispatch, ~onCancel, 0.0, "Loading Project...", true, "Loading")

        Logger.startOperation(
          ~module_="Sidebar",
          ~operation="PROJECT_LOAD",
          ~data={
            "filename": File.name(file),
            "size": File.size(file),
          },
          (),
        )

        let timeoutId = ReBindings.Window.setTimeout(() => {
          abortRequest()
          finalizeFailure("Project load timed out. Please retry.")
        }, timeoutMs)

        try {
          let projectDataResult = await ProjectManager.loadProject(
            file,
            ~signal,
            ~onProgress=(pct, _t, msg) => {
              if !loadSettled.contents {
                updateProgress(~dispatch, pct->Int.toFloat, msg, true, "Loading")
              }
            },
            ~opId,
          )

          ReBindings.Window.clearTimeout(timeoutId)

          if !loadSettled.contents {
            switch projectDataResult {
            | Ok((sessionId, projectData)) => {
                loadSettled := true
                ViewerSystem.resetState()
                dispatch(Actions.SetSessionId(sessionId))
                dispatch(Actions.LoadProject(projectData))
                UploadReport.showFromProjectData(projectData, ~getState, ~dispatch)

                Logger.endOperation(
                  ~module_="Sidebar",
                  ~operation="PROJECT_LOAD",
                  ~data={"success": true},
                  (),
                )
                updateProgress(~dispatch, 100.0, "Done", false, "")
                dispatch(Actions.DispatchAppFsmEvent(ProjectLoadComplete))
                NotificationManager.dispatch({
                  id: "",
                  importance: Success,
                  context: Operation("sidebar_load_project"),
                  message: "Project Loaded",
                  details: None,
                  action: None,
                  duration: NotificationTypes.defaultTimeoutMs(Success),
                  dismissible: true,
                  createdAt: Date.now(),
                })
              }
            | Error(msg) =>
              Logger.info(
                ~module_="SidebarLogic",
                ~message="PROJECT_LOAD_FAILED_DISPATCHING_NOTIF",
                ~data=Some({"error": msg}),
                (),
              )
              finalizeFailure(msg)
            }
          }
        } catch {
        | JsExn(exn) =>
          ReBindings.Window.clearTimeout(timeoutId)
          let msg = exn->JsExn.message->Option.getOr("Unexpected project load error")
          finalizeFailure(msg)
        | _ =>
          ReBindings.Window.clearTimeout(timeoutId)
          finalizeFailure("Unexpected project load error")
        }
      | None => ()
      }
    } catch {
    | _ => updateProgress(~dispatch, 0.0, "Error", false, "")
    }
    set_value(target, "")
  | _ => ()
  }
}

let handleDeleteScene = async (index: int, ~getState: unit => Types.state) => {
  let _ = await OptimisticAction.execute(~action=Actions.DeleteScene(index), ~apiCall=() => {
    let state = getState()
    switch state.sessionId {
    | Some(sid) =>
      let projectData = getProjectData(state)
      Api.ProjectApi.saveProject(sid, projectData)
    | None => Promise.resolve(Error("No active session"))
    }
  })
}

let isMissingPanoramaFile = (f: Types.file) => {
  switch f {
  | Url(u) => u == ""
  | Blob(_) | File(_) => false
  }
}

let repairRestoredState = (~restoredState: Types.state, ~currentState: Types.state) => {
  let repairedInventory =
    restoredState.inventory
    ->Belt.Map.String.toArray
    ->Belt.Array.reduce(Belt.Map.String.empty, (acc, (id, entry)) => {
      let restoredScene = entry.scene
      let repairedFile = if !isMissingPanoramaFile(restoredScene.file) {
        restoredScene.file
      } else {
        switch currentState.inventory->Belt.Map.String.get(id) {
        | Some(currentEntry) if !isMissingPanoramaFile(currentEntry.scene.file) =>
          currentEntry.scene.file
        | _ =>
          switch restoredScene.originalFile {
          | Some(f) if !isMissingPanoramaFile(f) => f
          | _ =>
            switch restoredScene.tinyFile {
            | Some(f) if !isMissingPanoramaFile(f) => f
            | _ => restoredScene.file
            }
          }
        }
      }

      let repairedScene = {...restoredScene, file: repairedFile}
      acc->Belt.Map.String.set(id, {...entry, scene: repairedScene})
    })

  let rebuilt = {...restoredState, inventory: repairedInventory}
  let activeScenes = SceneInventory.getActiveScenes(rebuilt.inventory, rebuilt.sceneOrder)
  let sceneCount = Belt.Array.length(activeScenes)
  let activeIndex = if sceneCount == 0 {
    -1
  } else {
    let boundedHigh = rebuilt.activeIndex > sceneCount - 1 ? sceneCount - 1 : rebuilt.activeIndex
    boundedHigh < 0 ? 0 : boundedHigh
  }

  {
    ...rebuilt,
    activeIndex,
    activeYaw: activeIndex == -1 ? 0.0 : rebuilt.activeYaw,
    activePitch: activeIndex == -1 ? 0.0 : rebuilt.activePitch,
  }
}

let handleDeleteSceneWithUndo = (
  index: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let state = getState()
  let action = Actions.DeleteScene(index)

  // 1. Capture state for potential undo
  let snapId = StateSnapshot.capture(state, action)

  // 2. Perform optimistic delete (local only)
  dispatch(action)

  let undoCalled = ref(false)

  let performUndo = () => {
    if !undoCalled.contents {
      undoCalled := true
      switch StateSnapshot.rollback(snapId) {
      | Some(restoredState) =>
        let repaired = repairRestoredState(~restoredState, ~currentState=getState())
        AppContext.restoreState(repaired)
        NotificationManager.dismiss("undo-delete-" ++ snapId)
        NotificationManager.dispatch({
          id: "undone-notif-" ++ snapId,
          importance: Info,
          context: UserAction("undo"),
          message: "Scene deletion undone",
          details: None,
          action: None,
          duration: 3000,
          dismissible: true,
          createdAt: Date.now(),
        })
      | None => ()
      }
    }
  }

  // 3. Set timer for backend synchronization (9.5s to give buffer for 9s notification)
  let _ = Window.setTimeout(() => {
    if !undoCalled.contents {
      let currentState = getState()
      switch currentState.sessionId {
      | Some(sid) =>
        let projectData = getProjectData(currentState)
        Api.ProjectApi.saveProject(sid, projectData)->ignore
      | None => ()
      }
    }
  }, 9500)

  // 4. Show notification with 9s timer and Undo shortcut
  NotificationManager.dispatch({
    id: "undo-delete-" ++ snapId,
    importance: Success,
    context: UserAction("delete_scene"),
    message: "Scene deleted. Press U to undo.",
    details: None,
    action: Some({
      label: "Undo",
      onClick: performUndo,
      shortcut: Some("u"),
    }),
    duration: 9000,
    dismissible: true,
    createdAt: Date.now(),
  })
}

let handleClearLinksWithUndo = (
  index: int,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
) => {
  let state = getState()
  let action = Actions.ClearHotspots(index)

  // 1. Capture state for potential undo
  let snapId = StateSnapshot.capture(state, action)

  // 2. Perform optimistic clear (local only)
  dispatch(action)

  let undoCalled = ref(false)

  let performUndo = () => {
    if !undoCalled.contents {
      undoCalled := true
      switch StateSnapshot.rollback(snapId) {
      | Some(restoredState) =>
        let repaired = repairRestoredState(~restoredState, ~currentState=getState())
        AppContext.restoreState(repaired)
        NotificationManager.dismiss("undo-clear-" ++ snapId)
        NotificationManager.dispatch({
          id: "undone-clear-notif-" ++ snapId,
          importance: Info,
          context: UserAction("undo"),
          message: "Hotspots restored",
          details: None,
          action: None,
          duration: 3000,
          dismissible: true,
          createdAt: Date.now(),
        })
      | None => ()
      }
    }
  }

  // 3. Set timer for backend synchronization
  let _ = Window.setTimeout(() => {
    if !undoCalled.contents {
      let currentState = getState()
      switch currentState.sessionId {
      | Some(sid) =>
        let projectData = getProjectData(currentState)
        Api.ProjectApi.saveProject(sid, projectData)->ignore
      | None => ()
      }
    }
  }, 9500)

  // 4. Show notification with 9s timer and Undo shortcut
  NotificationManager.dispatch({
    id: "undo-clear-" ++ snapId,
    importance: Success,
    context: UserAction("clear_links"),
    message: "Links cleared. Press U to undo.",
    details: None,
    action: Some({
      label: "Undo",
      onClick: performUndo,
      shortcut: Some("u"),
    }),
    duration: 9000,
    dismissible: true,
    createdAt: Date.now(),
  })
}

let handleExport = async (
  scenes: array<Types.scene>,
  ~tourName: string,
  ~projectData: option<JSON.t>=?,
  ~dispatch: Actions.action => unit=AppContext.getBridgeDispatch(),
  ~signal,
  ~onCancel,
) => {
  dispatch(DispatchAppFsmEvent(StartExport))
  let startedAtMs = Date.now()
  let exportSceneCount = scenes->Belt.Array.keep(s => s.floor->String.trim != "")->Belt.Array.length
  let knownTotalScenes = ref(exportSceneCount)
  let knownTotalUploadMb = ref(0.0)
  let lastEtaToastAtMs = ref(0.0)
  let lastPctSample = ref(0.0)
  let lastSampleAtMs = ref(startedAtMs)
  let emaProgressPerSecond = ref(0.0)
  let lastPackagedSceneSample = ref(0)
  let lastPackagedSceneAtMs = ref(startedAtMs)
  let emaSecondsPerScene = ref(0.0)
  let packagingSampleCount = ref(0)
  let lastUploadedMbSample = ref(0.0)
  let lastUploadedMbAtMs = ref(startedAtMs)
  let emaSecondsPerMb = ref(0.0)
  let uploadSampleCount = ref(0)
  let stableEtaSeconds = ref(0.0)
  let etaReady = ref(false)

  let opId = OperationLifecycle.start(
    ~type_=Export,
    ~scope=Blocking,
    ~phase="Preparing",
    ~meta=Logger.castToJson({
      "tourName": tourName,
    }),
    (),
  )
  OperationLifecycle.registerCancel(opId, onCancel)

  updateProgress(~dispatch, ~onCancel, 0.0, "Starting export...", true, "Export")
  EtaSupport.dispatchCalculatingEtaToast(
    ~id=exportProgressToastId,
    ~contextOperation="eta_export",
    ~prefix="Exporting",
    ~details=Some("Preparing export package"),
    (),
  )

  let handleExportProgress = (pct: float, _total: float, msg: string) => {
    updateProgress(~dispatch, ~onCancel, pct, msg, true, "Export")

    if pct > 0.0 && pct < 100.0 {
      let now = Date.now()
      let metrics = parseExportMetrics(msg)

      metrics.packagedScene->Option.forEach(((completed, total)) => {
        knownTotalScenes := total
        if completed > lastPackagedSceneSample.contents {
          let deltaScenes = completed - lastPackagedSceneSample.contents
          let deltaSeconds = (now -. lastPackagedSceneAtMs.contents) /. 1000.0
          if deltaScenes > 0 && deltaSeconds > 0.4 {
            let instSecondsPerScene = deltaSeconds /. Belt.Int.toFloat(deltaScenes)
            if emaSecondsPerScene.contents <= 0.0 {
              emaSecondsPerScene := instSecondsPerScene
            } else {
              emaSecondsPerScene :=
                0.72 *. emaSecondsPerScene.contents +. 0.28 *. instSecondsPerScene
            }
            packagingSampleCount := packagingSampleCount.contents + 1
          }
          lastPackagedSceneSample := completed
          lastPackagedSceneAtMs := now
        }
      })

      metrics.uploadedMb->Option.forEach(((uploadedMb, totalMb)) => {
        knownTotalUploadMb := totalMb
        if uploadedMb > lastUploadedMbSample.contents {
          let deltaMb = uploadedMb -. lastUploadedMbSample.contents
          let deltaSeconds = (now -. lastUploadedMbAtMs.contents) /. 1000.0
          if deltaMb > 0.1 && deltaSeconds > 0.4 {
            let instSecondsPerMb = deltaSeconds /. deltaMb
            if emaSecondsPerMb.contents <= 0.0 {
              emaSecondsPerMb := instSecondsPerMb
            } else {
              emaSecondsPerMb := 0.7 *. emaSecondsPerMb.contents +. 0.3 *. instSecondsPerMb
            }
            uploadSampleCount := uploadSampleCount.contents + 1
          }
          lastUploadedMbSample := uploadedMb
          lastUploadedMbAtMs := now
        }
      })

      let deltaPct = pct -. lastPctSample.contents
      let deltaSec = (now -. lastSampleAtMs.contents) /. 1000.0
      if deltaPct > 0.0 && deltaSec > 0.4 {
        let instRate = deltaPct /. deltaSec
        if emaProgressPerSecond.contents <= 0.0 {
          emaProgressPerSecond := instRate
        } else {
          emaProgressPerSecond := 0.82 *. emaProgressPerSecond.contents +. 0.18 *. instRate
        }
        lastPctSample := pct
        lastSampleAtMs := now
      }

      let elapsedSec = (now -. startedAtMs) /. 1000.0
      if (
        !etaReady.contents &&
        elapsedSec >= 10.0 &&
        (packagingSampleCount.contents >= 2 ||
        uploadSampleCount.contents >= 2 ||
        (pct >= 20.0 && emaProgressPerSecond.contents > 0.0))
      ) {
        etaReady := true
      }

      let shouldUpdateToast = now -. lastEtaToastAtMs.contents >= 1500.0
      if shouldUpdateToast {
        let remainingScenes = if knownTotalScenes.contents > lastPackagedSceneSample.contents {
          knownTotalScenes.contents - lastPackagedSceneSample.contents
        } else {
          0
        }
        let remainingMb = if knownTotalUploadMb.contents > lastUploadedMbSample.contents {
          knownTotalUploadMb.contents -. lastUploadedMbSample.contents
        } else {
          0.0
        }

        let etaBySceneRate = if emaSecondsPerScene.contents > 0.0 && remainingScenes > 0 {
          Some(emaSecondsPerScene.contents *. Belt.Int.toFloat(remainingScenes))
        } else {
          None
        }
        let etaByUploadRate = if emaSecondsPerMb.contents > 0.0 && remainingMb > 0.1 {
          Some(emaSecondsPerMb.contents *. remainingMb)
        } else {
          None
        }
        let etaByProgressSlope = if emaProgressPerSecond.contents > 0.0 {
          Some((100.0 -. pct) /. emaProgressPerSecond.contents)
        } else {
          None
        }
        let etaByGlobalAverage = if pct >= 1.0 {
          Some(elapsedSec /. pct *. (100.0 -. pct))
        } else {
          None
        }

        let blendedEta = EtaSupport.combineEtaCandidates(
          ~a=etaBySceneRate,
          ~b=etaByUploadRate,
          ~c=etaByProgressSlope,
          ~d=?etaByGlobalAverage,
        )->Option.map(raw =>
          if String.startsWith(msg, "Building your tour") {
            raw *. 1.08
          } else {
            raw
          }
        )

        let etaSeconds = switch blendedEta {
        | Some(candidate) if etaReady.contents =>
          let smoothed = if stableEtaSeconds.contents <= 0.0 {
            candidate
          } else {
            let raw = 0.8 *. stableEtaSeconds.contents +. 0.2 *. candidate
            let maxRise = stableEtaSeconds.contents +. 25.0
            let maxDrop = stableEtaSeconds.contents -. 16.0
            EtaSupport.clampFloat(~value=raw, ~minValue=Math.max(1.0, maxDrop), ~maxValue=maxRise)
          }
          stableEtaSeconds := smoothed
          Belt.Float.toInt(smoothed)
        | _ => 0
        }

        lastEtaToastAtMs := now
        if etaReady.contents {
          EtaSupport.dispatchEtaToast(
            ~id=exportProgressToastId,
            ~contextOperation="eta_export",
            ~prefix="Exporting",
            ~etaSeconds,
            ~details=Some("Export • " ++ msg),
            ~createdAt=now,
            (),
          )
        } else {
          EtaSupport.dispatchCalculatingEtaToast(
            ~id=exportProgressToastId,
            ~contextOperation="eta_export",
            ~prefix="Exporting",
            ~details=Some("Export • " ++ msg),
            ~createdAt=now,
            (),
          )
        }
      }
    }
  }

  try {
    let exportResult = await Exporter.exportTour(
      scenes,
      ~tourName,
      ~logo=AppContext.getBridgeState().logo,
      ~projectData?,
      ~signal,
      Some(handleExportProgress),
      ~opId,
    )
    switch exportResult {
    | Ok() => {
        EtaSupport.dismissEtaToast(exportProgressToastId)
        NotificationManager.dispatch({
          id: "",
          importance: Success,
          context: Operation("sidebar_export"),
          message: "Export complete",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Success),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 100.0, "Done", false, "")
        dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error("CANCELLED") => {
        EtaSupport.dismissEtaToast(exportProgressToastId)
        Logger.info(~module_="SidebarLogicHandler", ~message="EXPORT_CANCELLED_HANDLED", ())
        NotificationManager.dispatch({
          id: "",
          importance: Info,
          context: Operation("sidebar_export"),
          message: "Export cancelled",
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Info),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 0.0, "Cancelled", false, "")
        dispatch(DispatchAppFsmEvent(ExportComplete))
      }
    | Error(msg) => {
        EtaSupport.dismissEtaToast(exportProgressToastId)
        Logger.error(
          ~module_="SidebarLogicHandler",
          ~message="EXPORT_FAILED",
          ~data=Some({"error": msg}),
          (),
        )
        dispatch(DispatchAppFsmEvent(ExportComplete))
        NotificationManager.dispatch({
          id: "",
          importance: Error,
          context: Operation("sidebar_export"),
          message: "Export failed: " ++ msg,
          details: None,
          action: None,
          duration: NotificationTypes.defaultTimeoutMs(Error),
          dismissible: true,
          createdAt: Date.now(),
        })
        updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
      }
    }
  } catch {
  | JsExn(exn) =>
    EtaSupport.dismissEtaToast(exportProgressToastId)
    let msg = exn->JsExn.message->Option.getOr("Unexpected Error")
    Logger.error(
      ~module_="SidebarLogicHandler",
      ~message="EXPORT_FAILED_UNCAUGHT",
      ~data=Some({"error": msg}),
      (),
    )
    dispatch(DispatchAppFsmEvent(ExportComplete))
    NotificationManager.dispatch({
      id: "",
      importance: Error,
      context: Operation("sidebar_export"),
      message: "Export failed: " ++ msg,
      details: None,
      action: None,
      duration: NotificationTypes.defaultTimeoutMs(Error),
      dismissible: true,
      createdAt: Date.now(),
    })
    updateProgress(~dispatch, 0.0, "Error: " ++ msg, false, "")
  | _ =>
    EtaSupport.dismissEtaToast(exportProgressToastId)
    dispatch(DispatchAppFsmEvent(ExportComplete))
    updateProgress(~dispatch, 0.0, "Error: Unexpected Error", false, "")
  }
}
