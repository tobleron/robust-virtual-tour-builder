/* src/systems/TeaserPathfinder.res */


/* Re-export types from BackendApi for backward compatibility */
type transitionTarget = BackendApi.transitionTarget
type arrivalView = BackendApi.arrivalView
type step = BackendApi.step

/**
 * Calculates the "Walk Path" (Auto-Teaser) via Backend
 */
let getWalkPath = (scenes: array<Types.scene>, skipAutoForward: bool): Promise.t<array<step>> => {
  BackendApi.calculatePath({
    "type": "walk",
    "scenes": scenes,
    "skipAutoForward": skipAutoForward,
  })
}

/**
 * Calculates the path based on Timeline via Backend
 */
let getTimelinePath = (
  timeline: array<Types.timelineItem>,
  scenes: array<Types.scene>,
  skipAutoForward: bool,
): Promise.t<array<step>> => {
  BackendApi.calculatePath({
    "type": "timeline",
    "timeline": timeline,
    "scenes": scenes,
    "skipAutoForward": skipAutoForward,
  })
}
