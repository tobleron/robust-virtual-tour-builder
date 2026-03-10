open Types

let isUntaggedScene = (scene: scene): bool => {
  let normalized = scene.label->String.trim->String.toLowerCase
  normalized == "" || normalized->String.includes("untagged")
}

let bulkDeleteBlockReason = (state: state): option<string> => {
  let simulationBusy = switch state.simulation.status {
  | Idle => false
  | _ => true
  }

  let navBusy =
    switch state.navigationState.navigation {
    | Idle => false
    | _ => true
    } ||
    switch state.navigationState.navigationFsm {
    | IdleFsm => false
    | _ => true
    }

  if state.isLinking {
    Some("Linking mode is active.")
  } else if state.movingHotspot != None {
    Some("Finish moving hotspot placement first.")
  } else if simulationBusy {
    Some("Stop tour preview first.")
  } else if navBusy {
    Some("Wait for scene navigation to finish.")
  } else {
    switch state.appMode {
    | SystemBlocking(_) => Some("Please wait until the current system operation finishes.")
    | _ => None
    }
  }
}

let notifyInfo = (~message: string) => {
  NotificationManager.dispatch({
    id: "",
    importance: Info,
    context: Operation("label_menu"),
    message,
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Info),
    dismissible: true,
    createdAt: Date.now(),
  })
}

let notifyWarning = (~message: string, ~details: option<string>=?) => {
  NotificationManager.dispatch({
    id: "",
    importance: Warning,
    context: Operation("label_menu"),
    message,
    details,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Warning),
    dismissible: true,
    createdAt: Date.now(),
  })
}

let notifySuccess = (~message: string) => {
  NotificationManager.dispatch({
    id: "",
    importance: Success,
    context: Operation("label_menu"),
    message,
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(Success),
    dismissible: true,
    createdAt: Date.now(),
  })
}
