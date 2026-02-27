type operationId = string

type operationType =
  | Navigation
  | Simulation
  | Upload
  | Teaser
  | Export
  | ThumbnailGeneration
  | SceneLoad
  | ProjectLoad
  | ProjectSave
  | Unknown(string)

type scope =
  | Blocking
  | Ambient

type status =
  | Idle
  | Active({progress: float, message: option<string>})
  | Paused
  | Completed({result: option<string>})
  | Failed({error: string})
  | Cancelled

type task = {
  id: operationId,
  type_: operationType,
  scope: scope,
  phase: string,
  cancellable: bool,
  correlationId: option<string>,
  status: status,
  startedAt: float,
  updatedAt: float,
  meta: option<JSON.t>,
  visibleAfterMs: int,
}

type lifecycleStats = {
  active: int,
  completedTotal: int,
  leakedTotal: int,
}
