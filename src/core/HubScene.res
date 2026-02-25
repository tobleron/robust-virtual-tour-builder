/* src/core/HubScene.res - Hub Scene Detection and Management */

open Types

/**
 * A Hub Scene is a scene with 2 or more exit links.
 * Hub scenes have special behavior:
 * - Animate only on first visit (prevents animation fatigue)
 * - Auto-forward links appear as normal buttons in exported tours
 * - Teaser/simulation still auto-triggers for navigation flow
 */
let isHubScene = (scene: scene): bool => {
  // Count outgoing links (all hotspots are exit links in current architecture)
  Array.length(scene.hotspots) >= 2
}

/**
 * Check if a scene has already been visited (animated)
 */
let hasSceneAnimated = (sceneId: string, state: state): bool => {
  Array.includes(state.visitedScenes, sceneId)
}

/**
 * Mark a scene as having completed its first animation
 */
let markSceneAsAnimated = (sceneId: string, state: state): state => {
  if Array.includes(state.visitedScenes, sceneId) {
    state // Already marked
  } else {
    {...state, visitedScenes: [...state.visitedScenes, sceneId]}
  }
}

/**
 * Get the count of exit links for a scene
 */
let getExitLinkCount = (scene: scene): int => {
  Array.length(scene.hotspots)
}

/**
 * Reset visited scene tracking (e.g., when starting a new tour session)
 */
let resetVisitedScenes = (state: state): state => {
  {...state, visitedScenes: []}
}
