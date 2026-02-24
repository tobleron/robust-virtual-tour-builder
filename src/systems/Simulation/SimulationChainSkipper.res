/* src/systems/Simulation/SimulationChainSkipper.res */

open Types
@@warning("-45")

open SimulationTypes

let skipAutoForwardChain = (
  initialLink: enrichedLink,
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
    let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
    switch Belt.Array.get(activeScenes, currentLink.contents.targetIndex) {
    | Some(targetScene) =>
      // Check hotspot-level isAutoForward (the link we're traversing)
      let linkIsAutoForward = switch currentLink.contents.hotspot.isAutoForward {
      | Some(af) => af
      | None => targetScene.isAutoForward // Fallback to scene-level for backward compatibility
      }
      
      if !linkIsAutoForward {
        loop := false
      } else {
        if !Array.includes(visitedScenes, currentLink.contents.targetIndex) {
          onVisitScene(currentLink.contents.targetIndex)
          let _ = Array.push(skippedScenes, currentLink.contents.targetIndex)
        }
        switch SimulationNavigation.findBestNextLink(targetScene, state, visitedScenes) {
        | Some(jumpLink) =>
          currentLink := {
              ...jumpLink,
              hotspotIndex: originalHotspotIndex,
              hotspot: originalHotspot,
            }
          chainCounter := chainCounter.contents + 1
        | None => loop := false
        }
      }
    | None => loop := false
    }
  }
  {finalLink: currentLink.contents, skippedScenes}
}
