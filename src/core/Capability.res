open Types

type capability =
  | CanNavigate
  | CanEditHotspots
  | CanUpload
  | CanExport
  | CanMutateProject
  | CanStartSimulation
  | CanInteractWithViewer

module Policy = {
  let isActive = (status: OperationLifecycle.status): bool => {
    switch status {
    | Active(_) | Paused => true
    | Idle | Completed(_) | Failed(_) | Cancelled => false
    }
  }

  let anyActive = (
    operations: array<OperationLifecycle.task>,
    predicate: OperationLifecycle.task => bool,
  ): bool => {
    operations->Belt.Array.some(op => isActive(op.status) && predicate(op))
  }

  let isTypeActive = (
    operations: array<OperationLifecycle.task>,
    type_: OperationLifecycle.operationType,
  ): bool => {
    anyActive(operations, op => op.type_ == type_)
  }

  let isSystemLockedByMode = (appMode: Types.appMode): bool => {
    switch appMode {
    | Initializing => true
    | SystemBlocking(ProjectLoading(_))
    | SystemBlocking(Exporting(_))
    | SystemBlocking(Summary(_)) => true
    | SystemBlocking(Uploading(_))
    | SystemBlocking(CriticalError(_))
    | Interactive(_) => false
    }
  }

  let isSystemLockedByOps = (operations: array<OperationLifecycle.task>): bool => {
    anyActive(operations, op => {
      switch op.type_ {
      | ProjectLoad | Export => true
      | _ => false
      }
    })
  }

  let isSystemLocked = (
    ~appMode: Types.appMode,
    operations: array<OperationLifecycle.task>,
  ): bool => {
    isSystemLockedByMode(appMode) || isSystemLockedByOps(operations)
  }

  let evaluate = (
    ~capability: capability,
    ~appMode: Types.appMode,
    operations: array<OperationLifecycle.task>,
  ): bool => {
    if isSystemLocked(~appMode, operations) {
      false
    } else {
      let hasNavigation = isTypeActive(operations, Navigation)
      let hasSimulation = isTypeActive(operations, Simulation)
      let hasTeaser = isTypeActive(operations, Teaser)
      let hasUpload = isTypeActive(operations, Upload)
      let hasExport = isTypeActive(operations, Export)
      let hasProjectSave = isTypeActive(operations, ProjectSave)

      switch capability {
      | CanNavigate => !hasTeaser
      | CanEditHotspots => !(hasNavigation || hasSimulation || hasTeaser)
      | CanUpload => !hasUpload
      | CanExport => !(hasUpload || hasExport)
      | CanMutateProject =>
        !(hasUpload || hasSimulation || hasNavigation || hasProjectSave || hasTeaser)
      | CanStartSimulation => !(hasSimulation || hasNavigation || hasTeaser)
      | CanInteractWithViewer => !(hasNavigation || hasTeaser)
      }
    }
  }
}

let useCapability = (capability: capability): bool => {
  let uiSlice = AppContext.useUiSlice()
  let operations = OperationLifecycle.useOperations()

  React.useMemo3(
    () => Policy.evaluate(~capability, ~appMode=uiSlice.appMode, operations),
    (capability, uiSlice.appMode, operations),
  )
}

let useIsSystemLocked = (): bool => {
  let uiSlice = AppContext.useUiSlice()
  let operations = OperationLifecycle.useOperations()

  React.useMemo2(
    () => Policy.isSystemLocked(~appMode=uiSlice.appMode, operations),
    (uiSlice.appMode, operations),
  )
}
