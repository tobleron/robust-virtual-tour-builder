type rec file =
  | Url(string)
  | Blob(ReBindings.Blob.t)
  | File(ReBindings.File.t)

type linkInfo = {
  sceneIndex: int,
  hotspotIndex: int,
}

type screenCoords = {x: float, y: float}

type pathPoint = {
  yaw: float,
  pitch: float,
}

type pathSegment = {
  dist: float,
  yawDiff: float,
  pitchDiff: float,
  p1: pathPoint,
  p2: pathPoint,
}

type pathData = {
  startPitch: float,
  startYaw: float,
  startHfov: float,
  targetPitchForPan: float,
  targetYawForPan: float,
  targetHfovForPan: float,
  totalPathDistance: float,
  segments: array<pathSegment>,
  waypoints: array<pathPoint>,
  panDuration: float,
  arrivalYaw: float,
  arrivalPitch: float,
  arrivalHfov: float,
}

type journeyData = {
  journeyId: int,
  targetIndex: int,
  sourceIndex: int,
  hotspotIndex: int,
  arrivalYaw: float,
  arrivalPitch: float,
  arrivalHfov: float,
  previewOnly: bool,
  pathData: option<pathData>,
}

type navigationStatus =
  | Idle
  | Navigating(journeyData)
  | Previewing(linkInfo)

type transitionType =
  | Cut
  | Fade
  | Link
  | Unknown(string)

type transition = {
  @as("type") type_: transitionType,
  targetHotspotIndex: int,
  fromSceneName: option<string>,
}

type simulationStatus =
  | Idle
  | Running
  | Stopping
  | Paused

type simulationState = {
  status: simulationStatus,
  visitedScenes: array<int>,
  stoppingOnArrival: bool,
  skipAutoForwardGlobal: bool,
  lastAdvanceTime: float,
  pendingAdvanceId: option<int>,
  autoPilotJourneyId: int,
}

type viewFrame = {
  yaw: float,
  pitch: float,
  hfov: float,
}

type rec linkDraft = {
  pitch: float,
  yaw: float,
  camPitch: float,
  camYaw: float,
  camHfov: float,
  intermediatePoints: option<array<linkDraft>>,
}

type hotspot = {
  linkId: string,
  yaw: float,
  pitch: float,
  target: string,
  targetYaw: option<float>,
  targetPitch: option<float>,
  targetHfov: option<float>,
  startYaw: option<float>,
  startPitch: option<float>,
  startHfov: option<float>,
  isReturnLink: option<bool>,
  viewFrame: option<viewFrame>,
  returnViewFrame: option<viewFrame>,
  waypoints: option<array<viewFrame>>,
  displayPitch: option<float>,
  transition: option<string>,
  duration: option<int>,
}

type scene = {
  id: string,
  name: string,
  file: file,
  tinyFile: option<file>,
  originalFile: option<file>,
  hotspots: array<hotspot>,
  category: string,
  floor: string,
  label: string,
  quality: option<JSON.t>,
  colorGroup: option<string>,
  _metadataSource: string,
  categorySet: bool,
  labelSet: bool,
  isAutoForward: bool,
}

type timelineItem = {
  id: string,
  linkId: string,
  sceneId: string,
  targetScene: string,
  transition: string,
  duration: int,
}

type uploadReport = {
  success: array<string>,
  skipped: array<string>,
}

type updateMetadata = {
  category: option<string>,
  floor: option<string>,
  label: option<string>,
  isAutoForward: option<bool>,
}

type timelineUpdate = {
  transition: option<string>,
  duration: option<option<int>>, // Double option because duration can be null (meaning no change) or int
}

type project = {
  tourName: string,
  scenes: array<scene>,
  lastUsedCategory: string,
  exifReport: option<JSON.t>,
  sessionId: option<string>,
  deletedSceneIds: array<string>,
  timeline: array<timelineItem>,
}

type editorState =
  | Idle
  | Linking(linkDraft)
  | EditingMetadata(string) // sceneId

type qualityItem = {
  quality: SharedTypes.qualityAnalysis,
  newName: string,
}

type blockingState =
  | Uploading({progress: float})
  | Summary(uploadReport, array<qualityItem>)
  | ProjectLoading({name: string})
  | Exporting
  | CriticalError(string)

type appMode =
  | Initializing
  | InteractiveTouring(navigationStatus)
  | InteractiveAuthoring(editorState)
  | InteractiveSimulation(simulationState)
  | InteractiveTeaser
  | SystemBlocking(blockingState)

type state = {
  tourName: string,
  scenes: array<scene>,
  activeIndex: int,
  activeYaw: float,
  activePitch: float,
  appMode: appMode,
  isLinking: bool,
  transition: transition,
  exifReport: option<JSON.t>,
  linkDraft: option<linkDraft>,
  preloadingSceneIndex: int,
  isTeasing: bool,
  deletedSceneIds: array<string>,
  timeline: array<timelineItem>,
  activeTimelineStepId: option<string>,
  // Navigation State
  navigation: navigationStatus,
  navigationFsm: NavigationFSM.distinctState,
  // isSimulationMode: bool, // DEPRECATED in favor of simulation.status
  simulation: simulationState,
  incomingLink: option<linkInfo>,
  autoForwardChain: array<int>,
  pendingReturnSceneName: option<string>,
  currentJourneyId: int,
  lastUsedCategory: string,
  sessionId: option<string>,
}

/* --- Pathfinder API Types --- */

type transitionTarget = {
  yaw: float,
  pitch: float,
  targetName: string,
  timelineItemId: option<string>,
}

type arrivalView = pathPoint

type step = {
  idx: int,
  transitionTarget: option<transitionTarget>,
  arrivalView: arrivalView,
}

/* --- Request Types --- */

type pathRequest = {
  @as("type") type_: string,
  scenes: array<scene>,
  skipAutoForward: bool,
  timeline: option<array<timelineItem>>,
}

type sessionState = {
  tourName: string,
  activeIndex: int,
  activeYaw: float,
  activePitch: float,
  isLinking: bool,
  isTeasing: bool,
}

let fileToUrl = (f: file): string => {
  switch f {
  | Url(u) => u
  | Blob(b) => ReBindings.URL.createObjectURL(b)
  | File(f) => ReBindings.URL.createObjectURL(f)
  }
}
