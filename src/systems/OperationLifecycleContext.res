let isActiveStatus = status =>
  switch status {
  | OperationLifecycleTypes.Active(_)
  | OperationLifecycleTypes.Paused => true
  | _ => false
  }

let defaultVisibleAfterMs = type_ =>
  switch type_ {
  | OperationLifecycleTypes.Navigation => 1200
  | OperationLifecycleTypes.Upload => 700
  | OperationLifecycleTypes.Teaser => 250
  | OperationLifecycleTypes.ThumbnailGeneration => 1500
  | OperationLifecycleTypes.ProjectLoad
  | OperationLifecycleTypes.ProjectSave
  | OperationLifecycleTypes.Export => 500
  | OperationLifecycleTypes.SceneLoad => 800
  | OperationLifecycleTypes.Simulation => 1200
  | OperationLifecycleTypes.Unknown(_) => 800
  }

let selectContextOperation = (tasks: array<OperationLifecycleTypes.task>): option<
  OperationLifecycleTypes.task,
> => {
  let activeOps = tasks->Belt.Array.keep(t => isActiveStatus(t.status))

  activeOps
  ->Belt.Array.keep(t => t.scope == OperationLifecycleTypes.Blocking)
  ->Belt.SortArray.stableSortBy((a, b) => compare(b.startedAt, a.startedAt))
  ->Belt.Array.get(0)
  ->Option.orElse(
    activeOps
    ->Belt.Array.keep(t => t.scope == OperationLifecycleTypes.Ambient)
    ->Belt.SortArray.stableSortBy((a, b) => compare(b.startedAt, a.startedAt))
    ->Belt.Array.get(0),
  )
}
