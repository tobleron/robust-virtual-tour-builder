module NotificationHelpers = {
  let getNotificationType = (typeStr: string) => {
    switch typeStr {
    | "error" => #Error
    | "warning" => #Warning
    | "success" => #Success
    | _ => #Info
    }
  }
}

let notify = (msg, typeStr) => {
  let importance = switch typeStr {
  | "error" => NotificationTypes.Error
  | "warning" => NotificationTypes.Warning
  | "success" => NotificationTypes.Success
  | _ => NotificationTypes.Info
  }
  NotificationManager.dispatch({
    id: "",
    importance,
    context: Operation("upload_processor"),
    message: msg,
    details: None,
    action: None,
    duration: NotificationTypes.defaultTimeoutMs(importance),
    dismissible: true,
    createdAt: Date.now(),
  })
}
