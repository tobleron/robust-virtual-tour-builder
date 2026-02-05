/* src/core/AppFSM.res */
open Types

type event =
  | InitializeComplete
  | StartAuthoring
  | StopAuthoring
  | StartSimulation(simulationState)
  | StopSimulation
  | StartTeasing
  | StopTeasing
  | StartUpload
  | UploadProgress(float)
  | UploadComplete(uploadReport, array<qualityItem>)
  | CloseSummary
  | StartProjectLoad({name: string})
  | ProjectLoadComplete
  | ProjectLoadError(string)
  | StartExport
  | ExportComplete
  | ExportError(string)
  | CriticalErrorOccurred(string)
  | Reset

let toString = (mode: appMode) => {
  switch mode {
  | Initializing => "Initializing"
  | InteractiveTouring(Idle) => "InteractiveTouring(Idle)"
  | InteractiveTouring(Navigating(_)) => "InteractiveTouring(Navigating)"
  | InteractiveTouring(Previewing(_)) => "InteractiveTouring(Previewing)"
  | InteractiveAuthoring(Idle) => "InteractiveAuthoring(Idle)"
  | InteractiveAuthoring(Linking(_)) => "InteractiveAuthoring(Linking)"
  | InteractiveAuthoring(EditingMetadata(_)) => "InteractiveAuthoring(EditingMetadata)"
  | InteractiveSimulation(_) => "InteractiveSimulation"
  | InteractiveTeaser => "InteractiveTeaser"
  | SystemBlocking(Uploading(_)) => "SystemBlocking(Uploading)"
  | SystemBlocking(Summary(_)) => "SystemBlocking(Summary)"
  | SystemBlocking(ProjectLoading(_)) => "SystemBlocking(ProjectLoading)"
  | SystemBlocking(Exporting) => "SystemBlocking(Exporting)"
  | SystemBlocking(CriticalError(_)) => "SystemBlocking(CriticalError)"
  }
}

let transition = (currentMode: appMode, event: event): appMode => {
  let nextMode = switch (currentMode, event) {
  | (Initializing, InitializeComplete) => InteractiveTouring(Idle)
  | (Initializing, CriticalErrorOccurred(msg)) => SystemBlocking(CriticalError(msg))

  | (InteractiveTouring(_), StartAuthoring) => InteractiveAuthoring(Idle)
  | (InteractiveTouring(_), StartSimulation(simState)) => InteractiveSimulation(simState)
  | (InteractiveTouring(_), StartTeasing) => InteractiveTeaser
  | (InteractiveTouring(_), StartUpload) => SystemBlocking(Uploading({progress: 0.0}))

  | (InteractiveAuthoring(_), StopAuthoring) => InteractiveTouring(Idle)
  | (InteractiveAuthoring(_), StartUpload) => SystemBlocking(Uploading({progress: 0.0}))

  | (InteractiveSimulation(_), StopSimulation) => InteractiveTouring(Idle)

  | (InteractiveTeaser, StopTeasing) => InteractiveTouring(Idle)

  | (SystemBlocking(Uploading(_)), UploadProgress(p)) => SystemBlocking(Uploading({progress: p}))
  | (SystemBlocking(Uploading(_)), UploadComplete(report, quality)) =>
    SystemBlocking(Summary(report, quality))

  | (SystemBlocking(Summary(_)), CloseSummary) => InteractiveTouring(Idle)
  | (SystemBlocking(Summary(_)), StartUpload) => SystemBlocking(Uploading({progress: 0.0}))

  | (_, StartProjectLoad({name})) => SystemBlocking(ProjectLoading({name: name}))
  | (SystemBlocking(ProjectLoading(_)), ProjectLoadComplete) => InteractiveTouring(Idle)
  | (SystemBlocking(ProjectLoading(_)), ProjectLoadError(msg)) => SystemBlocking(CriticalError(msg))
  | (_, StartExport) => SystemBlocking(Exporting)
  | (SystemBlocking(Exporting), ExportComplete) => InteractiveTouring(Idle)
  | (SystemBlocking(Exporting), ExportError(msg)) => SystemBlocking(CriticalError(msg))

  | (_, CriticalErrorOccurred(msg)) => SystemBlocking(CriticalError(msg))
  | (_, Reset) => Initializing
  | (m, _) => m // Ignore invalid transitions
  }

  if nextMode != currentMode {
    Logger.debug(
      ~module_="AppFSM",
      ~message="TRANSITION",
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
