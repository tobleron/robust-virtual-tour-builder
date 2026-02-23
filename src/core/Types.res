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

type preloadTarget = {
  targetSceneId: string,
  attempt: int,
  isAnticipatory: bool,
}

type transitioningState = {
  fromSceneId: option<string>,
  toSceneId: string,
  progress: float,
  isPreview: bool,
}

type errorInfo = {
  code: string,
  recoveryTarget: option<string>,
}

type navigationFsmState =
  | IdleFsm
  | Preloading(preloadTarget)
  | Transitioning(transitioningState)
  | Stabilizing({targetSceneId: string})
  | ErrorFsm(errorInfo)

// Navigation domain slice type
type navigationState = {
  navigationFsm: navigationFsmState,
  navigation: navigationStatus,
  incomingLink: option<linkInfo>,
  autoForwardChain: array<int>,
  currentJourneyId: int,
}

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
  targetSceneId: option<string>,
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
  isAutoForward: option<bool>,
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

type sceneStatus = Active | Deleted(float) // timestamp of deletion

type sceneEntry = {
  scene: scene,
  status: sceneStatus,
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
  inventory: Belt.Map.String.t<sceneEntry>,
  sceneOrder: array<string>,
  lastUsedCategory: string,
  exifReport: option<JSON.t>,
  sessionId: option<string>,
  timeline: array<timelineItem>,
  logo: option<file>,
}

type editorState =
  | Idle
  | Linking(linkDraft)
  | EditingMetadata(string) // sceneId

type qualityItem = {
  quality: SharedTypes.qualityAnalysis,
  newName: string,
}

type uiMode =
  | Viewing
  | EditingHotspots
  | EditingMetadata(string)
  | Simulation(simulationState)
  | Teaser

type backgroundTask =
  | Uploading({progress: float})
  | GeneratingPreviews

type navigationEvent =
  | UserClickedScene({targetSceneId: string, previewOnly: bool})
  | PreloadStarted({targetSceneId: string})
  | StartAnticipatoryLoad({targetSceneId: string})
  | TextureLoaded({targetSceneId: string})
  | AnimationProgress(float)
  | TransitionComplete
  | StabilizeComplete
  | LoadTimeout
  | RecoveryTriggered({targetSceneId: string})
  | Reset
  | Aborted

type rec appFsmEvent =
  | InitializeComplete
  | StartAuthoring
  | StopAuthoring
  | StartSimulation(simulationState)
  | StopSimulation
  | StartTeasing
  | StopTeasing
  | StartUpload
  | UploadProgress(float)
  | UploadComplete(uploadReport, array<qualityItem>)
  | CloseSummary
  | StartProjectLoad({name: string})
  | ProjectLoadComplete
  | ProjectLoadError(string)
  | StartExport
  | ExportComplete
  | ExportError(string)
  | CriticalErrorOccurred(string)
  | Reset
  | NavigationEvent(navigationEvent)
  | SetUiMode(uiMode)

type interactiveState = {
  uiMode: uiMode,
  navigation: navigationFsmState,
  backgroundTask: option<backgroundTask>,
}

type blockingState =
  | Uploading({progress: float})
  | Summary(uploadReport, array<qualityItem>)
  | ProjectLoading({name: string, pendingAction: option<appFsmEvent>})
  | Exporting({pendingAction: option<appFsmEvent>})
  | CriticalError(string)

type appMode =
  | Initializing
  | Interactive(interactiveState)
  | SystemBlocking(blockingState)

type state = {
  tourName: string,
  inventory: Belt.Map.String.t<sceneEntry>,
  sceneOrder: array<string>,
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
  timeline: array<timelineItem>,
  activeTimelineStepId: option<string>,
  // Domain Slices
  navigationState: navigationState,
  // isSimulationMode: bool, // DEPRECATED in favor of simulation.status
  simulation: simulationState,
  pendingReturnSceneName: option<string>,
  lastUsedCategory: string,
  sessionId: option<string>,
  logo: option<file>,
  structuralRevision: int,
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
  timeline: option<array<timelineItem>>,
  activeTimelineStepId: option<string>,
}

/* --- Motion Manifest Types (motion-spec-v1) --- */

type motionAnimationSegment = {
  startYaw: float,
  endYaw: float,
  startPitch: float,
  endPitch: float,
  startHfov: float,
  endHfov: float,
  easing: string, // "linear", "cubic-bezier", etc.
  durationMs: int,
}

type motionTransitionOut = {
  @as("type") type_: string, // "crossfade"
  durationMs: int,
}

type motionShot = {
  sceneId: string,
  arrivalPose: viewFrame,
  animationSegments: array<motionAnimationSegment>,
  transitionOut: option<motionTransitionOut>,
  pathData: option<pathData>,
  waitBeforePanMs: int,
  blinkAfterPanMs: int,
}

type motionManifest = {
  version: string, // "motion-spec-v1"
  fps: int,
  canvasWidth: int,
  canvasHeight: int,
  includeIntroPan: bool,
  shots: array<motionShot>,
}

let fileToUrl = (f: file): string => {
  switch f {
  | Url(u) => u
  | Blob(b) => ReBindings.URL.createObjectURL(b)
  | File(f) => ReBindings.URL.createObjectURL(f)
  }
}
