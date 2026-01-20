open ReBindings

type t = {
  mutable viewerA: Nullable.t<Viewer.t>,
  mutable viewerB: Nullable.t<Viewer.t>,
  mutable activeViewerKey: ViewerTypes.viewerKey,
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
  mutable lastCategory: string,
  mutable lastFloor: string,
  mutable lastAppliedYaw: Nullable.t<float>,
  mutable lastAppliedPitch: Nullable.t<float>,
  mutable viewportSaveTimeout: Nullable.t<int>,
  mutable idleSnapshotTimeout: Nullable.t<int>,
  mutable loadingSceneId: Nullable.t<string>,
  mutable isSceneLoading: bool,
  mutable loadSafetyTimeout: Nullable.t<int>,
  mutable cachedFloorCircles: Nullable.t<Dom.element>, // NodeList proxy
  mutable lastSwitchTime: float,
  mutable linkingStartPoint: Nullable.t<{"x": float, "y": float}>,
  mutable lastMoveX: float,
  mutable lastMoveY: float,
  mutable lastMoveTime: float,
  mutable mouseVelocityX: float,
  mutable mouseVelocityY: float,
}

let state = {
  viewerA: Nullable.null,
  viewerB: Nullable.null,
  activeViewerKey: A,
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
  lastCategory: "indoor",
  lastFloor: "ground",
  lastAppliedYaw: Nullable.null,
  lastAppliedPitch: Nullable.null,
  viewportSaveTimeout: Nullable.null,
  idleSnapshotTimeout: Nullable.null,
  loadingSceneId: Nullable.null,
  isSceneLoading: false,
  loadSafetyTimeout: Nullable.null,
  cachedFloorCircles: Nullable.null,
  lastSwitchTime: 0.0,
  linkingStartPoint: Nullable.null,
  lastMoveX: 0.0,
  lastMoveY: 0.0,
  lastMoveTime: 0.0,
  mouseVelocityX: 0.0,
  mouseVelocityY: 0.0,
}

let getActiveViewer = () => {
  switch state.activeViewerKey {
  | A => state.viewerA
  | B => state.viewerB
  }
}

let getInactiveViewer = () => {
  switch state.activeViewerKey {
  | A => state.viewerB
  | B => state.viewerA
  }
}

let getActiveContainerId = () => {
  switch state.activeViewerKey {
  | A => "panorama-a"
  | B => "panorama-b"
  }
}

let getInactiveContainerId = () => {
  switch state.activeViewerKey {
  | A => "panorama-b"
  | B => "panorama-a"
  }
}

let resetState = () => {
  state.isSceneLoading = false
  state.loadingSceneId = Nullable.null
  state.lastSceneId = Nullable.null
  switch Nullable.toOption(state.loadSafetyTimeout) {
  | Some(t) => Window.clearTimeout(t)
  | None => ()
  }
  state.loadSafetyTimeout = Nullable.null
}
