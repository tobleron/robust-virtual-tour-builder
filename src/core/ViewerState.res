open ReBindings

type t = {
  mutable lastMouseEvent: Nullable.t<Dom.event>,
  mutable guide: Nullable.t<Dom.element>,
  mutable lastPreloadingIndex: int,
  mutable mouseXNorm: float,
  mutable mouseYNorm: float,
  mutable followLoopActive: bool,
  ratchetState: ViewerTypes.ratchetState,
  mutable lastSceneId: Nullable.t<string>,
  mutable lastHotspotCount: int,
  mutable lastIsLinking: bool,
  mutable lastFloor: string,
  mutable lastAppliedYaw: Nullable.t<float>,
  mutable lastAppliedPitch: Nullable.t<float>,
  mutable viewportSaveTimeout: Nullable.t<int>,
  mutable idleSnapshotTimeout: Nullable.t<int>,
  mutable loadSafetyTimeout: Nullable.t<int>,
  mutable cachedFloorCircles: Nullable.t<Dom.element>, // NodeList proxy
  mutable lastSwitchTime: float,
  mutable linkingStartPoint: Nullable.t<{"x": float, "y": float}>,
  mutable lastMoveX: float,
  mutable lastMoveY: float,
  mutable lastMoveTime: float,
  mutable mouseVelocityX: float,
  mutable mouseVelocityY: float,
  mutable isSwapping: bool, // Lock flag to prevent render updates during viewer swaps
}

let state = {
  lastMouseEvent: Nullable.null,
  guide: Nullable.null,
  lastPreloadingIndex: -1,
  mouseXNorm: 0.0,
  mouseYNorm: 0.0,
  followLoopActive: false,
  ratchetState: {
    pitchOffset: 0.0,
    yawOffset: 0.0,
    maxPitchOffset: 0.0,
    minPitchOffset: 0.0,
    maxYawOffset: 0.0,
    minYawOffset: 0.0,
  },
  lastSceneId: Nullable.null,
  lastHotspotCount: 0,
  lastIsLinking: false,
  lastFloor: "ground",
  lastAppliedYaw: Nullable.null,
  lastAppliedPitch: Nullable.null,
  viewportSaveTimeout: Nullable.null,
  idleSnapshotTimeout: Nullable.null,
  loadSafetyTimeout: Nullable.null,
  cachedFloorCircles: Nullable.null,
  lastSwitchTime: 0.0,
  linkingStartPoint: Nullable.null,
  lastMoveX: 0.0,
  lastMoveY: 0.0,
  lastMoveTime: 0.0,
  mouseVelocityX: 0.0,
  mouseVelocityY: 0.0,
  isSwapping: false,
}

let getActiveViewer = () => {
  ViewerPool.getActiveViewer()->Nullable.fromOption
}

let getInactiveViewer = () => {
  ViewerPool.getInactiveViewer()->Nullable.fromOption
}

let getActiveContainerId = () => {
  switch ViewerPool.getActive() {
  | Some(v) => v.containerId
  | None => "panorama-a"
  }
}

let getInactiveContainerId = () => {
  switch ViewerPool.getInactive() {
  | Some(v) => v.containerId
  | None => "panorama-b"
  }
}

let resetState = () => {
  state.lastSceneId = Nullable.null
  switch Nullable.toOption(state.loadSafetyTimeout) {
  | Some(t) => Window.clearTimeout(t)
  | None => ()
  }
  state.loadSafetyTimeout = Nullable.null

  ViewerPool.pool->Belt.Array.forEach(v => {
    ViewerPool.clearCleanupTimeout(v.id)
  })
}
