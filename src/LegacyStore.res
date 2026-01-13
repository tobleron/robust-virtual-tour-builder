/* src/LegacyStore.res */

/***
 * BINDINGS for the existing mutable legacy store (src/store.js).
 * 
 * This allows ReScript to:
 * 1. Read the current global state (scenes, hotspots, etc.)
 * 2. Call actions on the store (setActiveScene, etc.)
 * 
 * NOTE: Use Nullable.t for fields that might be missing/null in the JS object.
 */

// --- DATA TYPES ---

type transition = {
  @as("type") type_: Nullable.t<string>,
  targetHotspotIndex: int,
  fromSceneName: Nullable.t<string>,
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
  intermediatePoints: Nullable.t<array<linkDraft>>,
}

type hotspot = {
  linkId: string,
  yaw: float,
  pitch: float,
  target: string, // target scene name/id
  
  // Optional fields
  targetYaw: Nullable.t<float>,
  targetPitch: Nullable.t<float>,
  targetHfov: Nullable.t<float>,
  
  startYaw: Nullable.t<float>,
  startPitch: Nullable.t<float>,
  startHfov: Nullable.t<float>,
  
  isReturnLink: Nullable.t<bool>,
  viewFrame: Nullable.t<viewFrame>,
  returnViewFrame: Nullable.t<viewFrame>,
  waypoints: Nullable.t<array<viewFrame>>,
}

type scene = {
  id: string,
  name: string,
  file: string, // Preview URL/path
  tinyFile: Nullable.t<string>,
  originalFile: Nullable.t<string>,
  
  hotspots: array<hotspot>,
  
  category: string,
  floor: string,
  label: string,
  
  isAutoForward: Nullable.t<bool>,
}

type timelineItem = {
  id: string,
  linkId: string,
  sceneId: string,
  targetScene: string,
}

type state = {
  tourName: string,
  scenes: array<scene>,
  activeIndex: int,
  activeYaw: float,
  activePitch: float,
  isLinking: bool,
  transition: transition,
  linkDraft: Nullable.t<linkDraft>,
  isTeasing: bool,
  deletedSceneIds: array<string>,
  timeline: array<timelineItem>,
  activeTimelineStepId: Nullable.t<string>,
  preloadingSceneIndex: int,
}

type storeObject = {
  state: state,
}

// --- EXTERNAL BINDINGS ---

// Bind to the exported 'store' object
@module("./store.js") external store: storeObject = "store"

// Bindings for store methods (called as store.method(...))
@module("./store.js") @scope("store")
external setActiveScene: (
  ~index: int, 
  ~startYaw: float, 
  ~startPitch: float, 
  ~transition: Nullable.t<transition>
) => unit = "setActiveScene"

@module("./store.js") @scope("store") 
external notify: unit => unit = "notify"

@module("./store.js") @scope("store")
external getScenesByFloor: unit => dict<array<scene>> = "getScenesByFloor"

@module("./store.js") @scope("store")
external setActiveTimelineStep: Nullable.t<string> => unit = "setActiveTimelineStep"

// Helper to safely get the current scene
let getCurrentScene = () => {
  let idx = store.state.activeIndex
  if idx >= 0 && idx < Array.length(store.state.scenes) {
    Some(store.state.scenes[idx])
  } else {
    None
  }
}
