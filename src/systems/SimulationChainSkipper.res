open Types

/**
 * Chain Skipping Logic
 * 
 * When skip-auto-forward mode is enabled, this module handles skipping through
 * consecutive auto-forward ("bridge") scenes to land directly on the next
 * interactive scene. This prevents autopilot from pausing at intermediate scenes.
 *
 * The logic maintains the original hotspot for visual transitions but updates
 * the target to the final non-bridge scene.
 */
type skipResult = {
  finalLink: SimulationNavigation.enrichedLink,
  skippedScenes: array<int>,
}

/**
 * Skips through a chain of auto-forward scenes to find the next interactive scene.
 * 
 * @param initialLink - The starting link to potentially skip through
 * @param state - The global application state
 * @param visitedScenes - Array of already visited scene indices
 * @param onVisitScene - Callback to mark a scene as visited during chain skip
 * @returns skipResult with the final link and array of skipped scene indices
 */
let skipAutoForwardChain = (
  initialLink: SimulationNavigation.enrichedLink,
  state: state,
  visitedScenes: array<int>,
  onVisitScene: int => unit,
): skipResult => {
  let chainCounter = ref(0)
  let originalHotspotIndex = initialLink.hotspotIndex
  let originalHotspot = initialLink.hotspot
  let currentLink = ref(initialLink)
  let skippedScenes = []
  let loop = ref(true)

  while loop.contents && chainCounter.contents < 10 {
    switch Belt.Array.get(state.scenes, currentLink.contents.targetIndex) {
    | Some(targetScene) =>
      let isAuto = targetScene.isAutoForward
      if !isAuto {
        // Found a non-auto-forward scene, stop skipping
        loop := false
      } else {
        // This is an auto-forward scene, mark it as visited and continue
        if !Js.Array.includes(currentLink.contents.targetIndex, visitedScenes) {
          onVisitScene(currentLink.contents.targetIndex)
          let _ = Js.Array.push(currentLink.contents.targetIndex, skippedScenes)
        }

        // Find the next link from this bridge scene
        switch SimulationNavigation.findBestNextLink(targetScene, state, visitedScenes) {
        | Some(jumpLink) =>
          // Update to the new target but keep original hotspot for visuals
          currentLink := {
              ...jumpLink,
              SimulationNavigation.hotspotIndex: originalHotspotIndex,
              SimulationNavigation.hotspot: originalHotspot,
            }
          chainCounter := chainCounter.contents + 1
        | None => loop := false
        }
      }
    | None => loop := false
    }
  }

  {
    finalLink: currentLink.contents,
    skippedScenes,
  }
}
