open Types

let initialState: state = {
  tourName: "",
  scenes: [],
  activeIndex: -1,
  activeYaw: 0.0,
  activePitch: 0.0,
  isLinking: false,
  transition: {
    type_: None,
    targetHotspotIndex: -1,
    fromSceneName: None,
  },
  lastUploadReport: {
    success: [],
    skipped: [],
  },
  exifReport: None,
  linkDraft: None,
  preloadingSceneIndex: -1,
  isTeasing: false,
  deletedSceneIds: [],
  timeline: [],
  activeTimelineStepId: None,
  navigation: Idle,
  isSimulationMode: false,
  incomingLink: None,
  autoForwardChain: [],
  pendingReturnSceneName: None,
  currentJourneyId: 0,
}
