let cancelTask = (~taskOpt, ~abortTask, ~cancelOp) => {
  switch taskOpt {
  | Some(task) =>
    abortTask(task)
    cancelOp(task)
  | None => ()
  }
}

let resetSupervisorState = (
  ~currentTaskRef,
  ~statusRef,
  ~taskCounterRef,
  ~runIdRef,
  ~idleStatus,
) => {
  currentTaskRef := None
  statusRef := idleStatus
  taskCounterRef := 0
  runIdRef := 0
}

let advanceStatus = (~statusRef, ~newStatus, ~notify, ~onProgress) => {
  if statusRef.contents == newStatus {
    None
  } else {
    let prevStatus = statusRef.contents
    statusRef := newStatus
    notify()
    onProgress(newStatus)
    Some(prevStatus)
  }
}

let currentTaskIdString = (~currentTaskOpt, ~getId) =>
  switch currentTaskOpt {
  | Some(t) => getId(t)
  | None => "none"
  }
