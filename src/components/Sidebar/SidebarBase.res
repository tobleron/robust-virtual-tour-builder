/* src/components/Sidebar/SidebarBase.res */

module SidebarTypes = {
  type publishProfile = [
    | #hd
    | #k2
    | #k4
    | #standalone2k
    | #standaloneHdLandscapeTouch
    | #standalone2kLandscapeTouch
    | #standalone4kLandscapeTouch
  ]

  type procState = {
    active: bool,
    progress: float,
    message: string,
    phase: string,
    error: bool,
  }

  type file = ReBindings.File.t

  type publishOptions = {
    selectedProfiles: array<publishProfile>,
    includeLogo: bool,
    includeMarketing: bool,
  }

  type processingPayload = {
    "active": bool,
    "progress": float,
    "message": string,
    "phase": string,
    "error": bool,
    "onCancel": unit => unit,
    "cancellable": bool,
    "eta": option<string>,
  }
}

let lastPct = ref(0.0)

let updateProgress = (
  ~dispatch: Actions.action => unit,
  ~onCancel=() => (),
  ~eta: option<string>=?,
  pct,
  msg,
  active,
  phase,
) => {
  /* Monotonic enforcement: never go backwards during an active operation */
  let effectivePct = if active && pct > 0.0 {
    let clamped = Math.max(pct, lastPct.contents)
    lastPct := clamped
    clamped
  } else if !active {
    lastPct := 0.0
    pct
  } else {
    pct
  }

  EventBus.dispatch(
    UpdateProcessing({
      "active": active,
      "progress": effectivePct,
      "message": msg,
      "phase": phase,
      "error": false,
      "onCancel": onCancel,
      "cancellable": true,
      "eta": eta,
    }),
  )
  if active {
    dispatch(DispatchAppFsmEvent(UploadProgress(effectivePct)))
  }
}

let getProjectData = (state: Types.state) => {
  ProjectSystem.encodeProjectFromState(state)
}
