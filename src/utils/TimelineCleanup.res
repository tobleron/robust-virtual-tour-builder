/* src/utils/TimelineCleanup.res */
/* Migration utility to clean polluted timelines from duplicate/orphaned entries */

open Types

type cleanupResult = {
  timelineItemsBefore: int,
  timelineItemsAfter: int,
  removedCount: int,
  removedLinkIds: array<string>,
}

/**
 * Migrate scene-level isAutoForward to hotspot-level for backward compatibility.
 * If a scene has isAutoForward: true, set all its hotspots to isAutoForward: Some(true).
 * This ensures link-level auto-forward works correctly with existing projects.
 */
let migrateSceneAutoForwardToHotspots = (state: state): state => {
  let updatedInventory = state.inventory->Belt.Map.String.map(entry => {
    let scene = entry.scene
    if scene.isAutoForward && Belt.Array.length(scene.hotspots) > 0 {
      // Migrate: set all hotspots to isAutoForward: Some(true)
      let updatedHotspots = scene.hotspots->Belt.Array.map(h => {
        {...h, isAutoForward: Some(true)}
      })
      {...entry, scene: {...scene, hotspots: updatedHotspots, isAutoForward: false}}
    } else {
      entry
    }
  })
  {...state, inventory: updatedInventory}
}

/**
 * Collect all valid linkIds from all scenes in the inventory
 */
let collectValidLinkIds = (inventory: Belt.Map.String.t<sceneEntry>): Belt.Set.String.t => {
  let linkIdsSet = ref(Belt.Set.String.empty)
  inventory->Belt.Map.String.forEach((_id, entry) => {
    let linkIds = entry.scene.hotspots->Belt.Array.map(h => h.linkId)->Belt.Set.String.fromArray
    linkIdsSet.contents = Belt.Set.String.union(linkIdsSet.contents, linkIds)
  })
  linkIdsSet.contents
}

/**
 * Simulate tour traversal to determine the correct timeline order.
 * This follows the same logic as the simulation (findBestNextLinkByLinkId).
 * Returns linkIds in visit order.
 */
let simulateTourOrder = (state: state): array<string> => {
  let activeScenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  if Belt.Array.length(activeScenes) == 0 {
    []
  } else {
    let visitedLinkIds = ref([])
    let currentSceneIdx = ref(0)
    let maxSteps = Belt.Array.length(activeScenes) * 3 // Safety limit
    let step = ref(0)

    while step.contents < maxSteps {
      step := step.contents + 1
      switch Belt.Array.get(activeScenes, currentSceneIdx.contents) {
      | Some(currentScene) =>
        // Find best next link using linkId-based tracking
        let allLinks =
          currentScene.hotspots
          ->Belt.Array.mapWithIndex((_i, hs) => {
            let targetIdx = HotspotTarget.resolveSceneIndex(activeScenes, hs)
            switch targetIdx {
            | Some(idx) =>
              let isVisited = Array.includes(visitedLinkIds.contents, hs.linkId)
              // Use hotspot-level isAutoForward (link-level takes priority)
              let isBridge = switch hs.isAutoForward {
              | Some(af) => af
              | None =>
                Belt.Array.get(activeScenes, idx)
                ->Option.map(s => s.isAutoForward)
                ->Option.getOr(false)
              }
              Some((hs.linkId, idx, isVisited, isBridge))
            | None => None
            }
          })
          ->Belt.Array.keepMap(x => x)

        // Find first unvisited link (same priority logic as SimulationNavigation)
        let nextLinkOpt = Array.find(allLinks, l => {
          let (_, _, v, b) = l
          !v && !b
        })->Option.orElse(
          Array.find(allLinks, l => {
            let (_, _, v, b) = l
            !v && b
          })->Option.orElse(
            Array.find(allLinks, l => {
              let (_, _, v, b) = l
              !v && b
            }),
          ),
        )

        switch nextLinkOpt {
        | Some((linkId, targetIdx, _, _)) =>
          // Mark this link as visited
          visitedLinkIds.contents = Belt.Array.concat(visitedLinkIds.contents, [linkId])
          currentSceneIdx := targetIdx
        | None =>
          // No more unvisited links - tour complete
          step := maxSteps
        }
      | None => step := maxSteps
      }
    }

    visitedLinkIds.contents
  }
}

/**
 * Clean timeline by removing items with linkIds that don't exist in any scene
 * This fixes the "timeline pollution" bug where old timeline entries weren't cleaned up
 * when hotspots were edited or deleted
 * Returns cleanup result with statistics
 */
let cleanupTimeline = (state: state): cleanupResult => {
  let timelineItemsBefore = Belt.Array.length(state.timeline)

  // Collect all valid linkIds from all scenes
  let validLinkIds = collectValidLinkIds(state.inventory)

  // Keep only timeline items with valid linkIds
  let cleanedTimeline =
    state.timeline->Belt.Array.keep(t => Belt.Set.String.has(validLinkIds, t.linkId))

  let timelineItemsAfter = Belt.Array.length(cleanedTimeline)
  let removedCount = timelineItemsBefore - timelineItemsAfter

  // Collect removed linkIds for reporting
  let removedLinkIds =
    state.timeline
    ->Belt.Array.keep(t => !Belt.Set.String.has(validLinkIds, t.linkId))
    ->Belt.Array.map(t => t.linkId)

  {
    timelineItemsBefore,
    timelineItemsAfter,
    removedCount,
    removedLinkIds,
  }
}

/**
 * Apply timeline cleanup and reorder by tour traversal order.
 *
 * Cleanup strategy:
 * 1. Remove timeline items with linkIds that don't exist in any hotspot (orphaned)
 * 2. Reorder remaining items by simulation tour order (chronological visit order)
 * 3. Keep only the LAST timeline item for each unique linkId (removes duplicates from edits)
 */
let applyCleanup = (state: state): (state, cleanupResult) => {
  let timelineItemsBefore = Belt.Array.length(state.timeline)

  // Collect all valid linkIds from all scenes
  let validLinkIds = collectValidLinkIds(state.inventory)

  // Step 1: Remove orphaned items (linkIds not in any hotspot)
  let afterOrphanRemoval =
    state.timeline->Belt.Array.keep(t => Belt.Set.String.has(validLinkIds, t.linkId))

  // Step 2: Remove duplicates - keep only the LAST item for each linkId
  let seenLinkIds = ref(Belt.Set.String.empty)
  let dedupedTimeline =
    afterOrphanRemoval
    ->Belt.Array.reverse
    ->Belt.Array.keep(t => {
      let alreadySeen = Belt.Set.String.has(seenLinkIds.contents, t.linkId)
      seenLinkIds.contents = Belt.Set.String.add(seenLinkIds.contents, t.linkId)
      !alreadySeen
    })
    ->Belt.Array.reverse

  // Step 3: Reorder by tour traversal order (TIMELINE = CHRONOLOGICAL ORDER)
  let tourOrder = simulateTourOrder(state)
  let linkIdToOrderIndex =
    tourOrder
    ->Belt.Array.mapWithIndex((i, lid) => (lid, i))
    ->Belt.Map.String.fromArray

  let reorderedTimeline = Belt.Array.copy(dedupedTimeline)
  reorderedTimeline->Array.sort((a, b) => {
    let idxA = linkIdToOrderIndex->Belt.Map.String.get(a.linkId)->Option.getOr(999999)
    let idxB = linkIdToOrderIndex->Belt.Map.String.get(b.linkId)->Option.getOr(999999)
    Belt.Int.toFloat(idxA - idxB)
  })

  let timelineItemsAfter = Belt.Array.length(reorderedTimeline)
  let removedCount = timelineItemsBefore - timelineItemsAfter

  // Collect removed linkIds for reporting
  let removedLinkIds =
    state.timeline
    ->Belt.Array.keep(t => !Belt.Array.some(reorderedTimeline, dt => dt.id == t.id))
    ->Belt.Array.map(t => t.linkId)

  // Clear active timeline step if it was removed
  let activeTimelineStepId = switch state.activeTimelineStepId {
  | Some(stepId) =>
    let stillExists = reorderedTimeline->Belt.Array.some(t => t.id == stepId)
    stillExists ? Some(stepId) : None
  | None => None
  }

  let result = {
    timelineItemsBefore,
    timelineItemsAfter,
    removedCount,
    removedLinkIds,
  }

  ({...state, timeline: reorderedTimeline, activeTimelineStepId}, result)
}
