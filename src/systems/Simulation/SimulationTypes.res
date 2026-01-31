/* src/systems/Simulation/SimulationTypes.res */

open Types

type enrichedLink = {
  hotspot: hotspot,
  hotspotIndex: int,
  targetIndex: int,
  isVisited: bool,
  isReturn: bool,
  isBridge: bool,
}

type skipResult = {
  finalLink: enrichedLink,
  skippedScenes: array<int>,
}

type arrivalView = {
  yaw: float,
  pitch: float,
}

type transitionTarget = {
  yaw: float,
  pitch: float,
  targetName: string,
  startYaw: float,
  startPitch: float,
  waypoints: array<viewFrame>,
}

type pathStep = {
  idx: int,
  transitionTarget: option<transitionTarget>,
  arrivalView: arrivalView,
}
