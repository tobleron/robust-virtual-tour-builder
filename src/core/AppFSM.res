/* src/core/AppFSM.res */
open Types

type event = appFsmEvent

let toString = (mode: appMode) => {
  switch mode {
  | Initializing => "Initializing"
  | Interactive(s) => {
      let uiStr = switch s.uiMode {
      | Viewing => "Viewing"
      | EditingHotspots => "EditingHotspots"
      | EditingMetadata(_) => "EditingMetadata"
      | Simulation(_) => "Simulation"
      | Teaser => "Teaser"
      }
      let navStr = NavigationFSM.toString(s.navigation)
      let taskStr = switch s.backgroundTask {
      | Some(Uploading({progress})) => "Uploading(" ++ Float.toString(progress) ++ ")"
      | Some(GeneratingPreviews) => "GeneratingPreviews"
      | None => "None"
      }
      "Interactive(" ++ uiStr ++ ", " ++ navStr ++ ", " ++ taskStr ++ ")"
    }
  | SystemBlocking(Uploading(_)) => "SystemBlocking(Uploading)"
  | SystemBlocking(Summary(_)) => "SystemBlocking(Summary)"
  | SystemBlocking(ProjectLoading(_)) => "SystemBlocking(ProjectLoading)"
  | SystemBlocking(Exporting(_)) => "SystemBlocking(Exporting)"
  | SystemBlocking(CriticalError(_)) => "SystemBlocking(CriticalError)"
  }
}

let eventToString = (e: event) => {
  switch e {
  | InitializeComplete => "InitializeComplete"
  | CriticalErrorOccurred(_) => "CriticalErrorOccurred"
  | StartAuthoring => "StartAuthoring"
  | StopAuthoring => "StopAuthoring"
  | StartSimulation(_) => "StartSimulation"
  | StopSimulation => "StopSimulation"
  | StartTeasing => "StartTeasing"
  | StopTeasing => "StopTeasing"
  | StartUpload => "StartUpload"
  | UploadProgress(_) => "UploadProgress"
  | UploadComplete(_, _) => "UploadComplete"
  | NavigationEvent(_) => "NavigationEvent"
  | StartProjectLoad(_) => "StartProjectLoad"
  | ProjectLoadComplete => "ProjectLoadComplete"
  | ProjectLoadError(_) => "ProjectLoadError"
  | StartExport => "StartExport"
  | ExportComplete => "ExportComplete"
  | ExportError(_) => "ExportError"
  | CloseSummary => "CloseSummary"
  | Reset => "Reset"
  | SetUiMode(_) => "SetUiMode"
  }
}

let rec transition = (currentMode: appMode, event: event): appMode => {
  let nextMode = switch (currentMode, event) {
  | (Initializing, InitializeComplete) =>
    Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None})
  | (Initializing, CriticalErrorOccurred(msg)) => SystemBlocking(CriticalError(msg))

  // --- Interactive Transitions ---
  | (Interactive(s), StartAuthoring) => Interactive({...s, uiMode: EditingHotspots})
  | (Interactive(s), StopAuthoring) => Interactive({...s, uiMode: Viewing})
  | (Interactive(s), StartSimulation(simState)) => Interactive({...s, uiMode: Simulation(simState)})
  | (Interactive(s), StopSimulation) => Interactive({...s, uiMode: Viewing})
  | (Interactive(s), StartTeasing) => Interactive({...s, uiMode: Teaser})
  | (Interactive(s), StopTeasing) => Interactive({...s, uiMode: Viewing})

  // --- Background Tasks (Ambient) ---
  | (Interactive(s), StartUpload) =>
    Interactive({...s, backgroundTask: Some(Uploading({progress: 0.0}))})
  | (Interactive(s), UploadProgress(p)) =>
    switch s.backgroundTask {
    | Some(Uploading(_)) => Interactive({...s, backgroundTask: Some(Uploading({progress: p}))})
    | _ => currentMode
    }
  | (Interactive(s), UploadComplete(report, quality)) => {
      let processedCount = Belt.Array.length(report.success) + Belt.Array.length(report.skipped)
      if processedCount <= 1 {
        Interactive({...s, backgroundTask: None})
      } else {
        // Multi-upload: show summary modal
        SystemBlocking(Summary(report, quality))
      }
    }

  | (Interactive(s), NavigationEvent(navEvent)) =>
    Interactive({...s, navigation: NavigationFSM.reducer(s.navigation, navEvent)})

  // --- Blocking & Buffering ---
  | (_, StartProjectLoad({name})) => SystemBlocking(ProjectLoading({name, pendingAction: None}))
  | (SystemBlocking(ProjectLoading(s)), ProjectLoadComplete) =>
    let next = Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None})
    switch s.pendingAction {
    | Some(a) => transition(next, a)
    | None => next
    }
  | (SystemBlocking(ProjectLoading(_s)), ProjectLoadError(msg)) =>
    SystemBlocking(CriticalError(msg))
  | (SystemBlocking(ProjectLoading(s)), e) =>
    // Buffer the event if it's an interaction attempt
    switch e {
    | StartAuthoring
    | StartSimulation(_)
    | StartTeasing
    | StartUpload
    | NavigationEvent(_) =>
      SystemBlocking(ProjectLoading({...s, pendingAction: Some(e)}))
    | _ => currentMode // Ignore other system events
    }

  | (_, StartExport) => SystemBlocking(Exporting({pendingAction: None}))
  | (SystemBlocking(Exporting(s)), ExportComplete) =>
    let next = Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None})
    switch s.pendingAction {
    | Some(a) => transition(next, a)
    | None => next
    }
  | (SystemBlocking(Exporting(_s)), ExportError(msg)) => SystemBlocking(CriticalError(msg))
  | (SystemBlocking(Exporting(_s)), e) =>
    switch e {
    | StartAuthoring
    | StartSimulation(_)
    | StartTeasing
    | StartUpload
    | NavigationEvent(_) =>
      SystemBlocking(Exporting({pendingAction: Some(e)}))
    | _ => currentMode
    }

  | (SystemBlocking(Summary(_)), CloseSummary) =>
    Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None})
  | (SystemBlocking(Summary(_)), StartUpload) =>
    Interactive({
      uiMode: Viewing,
      navigation: IdleFsm,
      backgroundTask: Some(Uploading({progress: 0.0})),
    })

  | (_, CriticalErrorOccurred(msg)) => SystemBlocking(CriticalError(msg))
  | (_, Reset) => Initializing

  // --- Default Catch-all ---
  | (m, _) => m
  }

  if nextMode != currentMode {
    Logger.debug(
      ~module_="AppFSM",
      ~message="TRANSITION_MODE",
      ~data=Some({
        "from": toString(currentMode),
        "to": toString(nextMode),
      }),
      (),
    )
  }
  nextMode
}

let init = (): unit => {
  Logger.initialized(~module_="AppFSM")
}
