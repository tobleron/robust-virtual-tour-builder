open ReBindings

type t = {
  lastMouseEvent: Nullable.t<Dom.event>,
  guide: Nullable.t<Dom.element>,
  lastPreloadingIndex: int,
  mouseXNorm: float,
  mouseYNorm: float,
  followLoopActive: bool,
  ratchetState: ViewerTypes.ratchetState,
  lastSceneId: Nullable.t<string>,
  lastHotspotCount: int,
  lastIsLinking: bool,
  lastFloor: string,
  lastAppliedYaw: Nullable.t<float>,
  lastAppliedPitch: Nullable.t<float>,
  viewportSaveTimeout: Nullable.t<int>,
  idleSnapshotTimeout: Nullable.t<int>,
  loadSafetyTimeout: Nullable.t<int>,
  cachedFloorCircles: Nullable.t<Dom.element>, // NodeList proxy
  linkingStartPoint: Nullable.t<{"x": float, "y": float}>,
  lastMoveX: float,
  lastMoveY: float,
  lastMoveTime: float,
  mouseVelocityX: float,
  mouseVelocityY: float,
}

let state = ref({
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
  linkingStartPoint: Nullable.null,
  lastMoveX: 0.0,
  lastMoveY: 0.0,
  lastMoveTime: 0.0,
  mouseVelocityX: 0.0,
  mouseVelocityY: 0.0,
})

let resetState = () => {
  state := {...state.contents, lastSceneId: Nullable.null}
  switch Nullable.toOption(state.contents.loadSafetyTimeout) {
  | Some(t) => Window.clearTimeout(t)
  | None => ()
  }
  state := {...state.contents, loadSafetyTimeout: Nullable.null}
}
