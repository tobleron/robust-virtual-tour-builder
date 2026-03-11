type taskSeed = {
  controller: BrowserBindings.AbortController.t,
  taskId: string,
  epoch: int,
  signal: BrowserBindings.AbortSignal.t,
  startedAt: float,
  opId: OperationLifecycle.operationId,
}

let cancelTaskWithLog = (
  ~taskOpt,
  ~targetSceneId: string,
  ~abortTask,
  ~cancelOp,
  ~getTaskId,
  ~getTargetSceneId,
) => {
  switch taskOpt {
  | Some(task) =>
    abortTask(task)
    cancelOp(task)
    Logger.debug(
      ~module_="NavigationSupervisor",
      ~message="PREVIOUS_TASK_CANCELLED",
      ~data=Some({
        "previousTaskId": getTaskId(task),
        "previousSceneId": getTargetSceneId(task),
        "newSceneId": targetSceneId,
      }),
      (),
    )
  | None => ()
  }
}

let makeTaskSeed = (~targetSceneId: string, ~taskCounterRef, ~runIdRef) => {
  let controller = BrowserBindings.AbortController.make()
  let signal = BrowserBindings.AbortController.signal(controller)
  taskCounterRef := taskCounterRef.contents + 1
  runIdRef := runIdRef.contents + 1
  let taskId = `task_${Date.now()->Float.toString}_${taskCounterRef.contents->Belt.Int.toString}`
  let opId = OperationLifecycle.start(
    ~type_=Navigation,
    ~scope=Blocking,
    ~phase="Loading",
    ~meta=Logger.castToJson({"targetSceneId": targetSceneId}),
    (),
  )
  {
    controller,
    taskId,
    epoch: runIdRef.contents,
    signal,
    startedAt: Date.now(),
    opId,
  }
}

let updateLifecyclePhase = (~currentTaskOpt, ~newStatus, ~getOpId, ~isSwapping, ~isStabilizing) => {
  let update = (progressValue, phase) =>
    currentTaskOpt->Option.forEach(task =>
      getOpId(task)->Option.forEach(id =>
        OperationLifecycle.progress(id, progressValue, ~phase, ())
      )
    )

  if isSwapping(newStatus) {
    update(50.0, "Swapping")
  } else if isStabilizing(newStatus) {
    update(80.0, "Stabilizing")
  }
}
