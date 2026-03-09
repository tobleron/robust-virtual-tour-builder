open Types

let handleAddHotspot = (state: state, sceneIndex: int, hotspot: hotspot): state => {
  HotspotHelpersLogic.handleAddHotspotState(state, sceneIndex, hotspot)
}

let handleRemoveHotspot = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  HotspotHelpersLogic.handleRemoveHotspotState(state, sceneIndex, hotspotIndex)
}

let handleClearHotspots = (state: state, sceneIndex: int): state => {
  HotspotHelpersLogic.handleClearHotspotsState(state, sceneIndex)
}

let handleUpdateHotspotTargetView = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  yaw: float,
  pitch: float,
  hfov: float,
): state => {
  HotspotHelpersLogic.handleUpdateHotspotTargetViewState(
    state,
    sceneIndex,
    hotspotIndex,
    yaw,
    pitch,
    hfov,
  )
}

let handleUpdateHotspotMetadata = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  metadata: JSON.t,
): state => {
  HotspotHelpersLogic.handleUpdateHotspotMetadataState(
    state,
    sceneIndex,
    hotspotIndex,
    metadata,
  )
}

let handleStartMovingHotspot = (state: state, sceneIndex: int, hotspotIndex: int): state => {
  HotspotHelpersLogic.handleStartMovingHotspotState(state, sceneIndex, hotspotIndex)
}

let handleStopMovingHotspot = (state: state): state => {
  {...state, movingHotspot: None}
}

let handleCommitHotspotMove = (
  state: state,
  sceneIndex: int,
  hotspotIndex: int,
  yaw: float,
  pitch: float,
): state => {
  HotspotHelpersLogic.handleCommitHotspotMoveState(state, sceneIndex, hotspotIndex, yaw, pitch)
}

let canEnableAutoForward = (scenes: array<scene>, sceneIndex: int, hotspotIndex: int): bool => {
  HotspotHelpersLogic.canEnableAutoForwardState(scenes, sceneIndex, hotspotIndex)
}
