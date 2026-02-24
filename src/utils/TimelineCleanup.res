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
  let cleanedTimeline = state.timeline->Belt.Array.keep(t =>
    Belt.Set.String.has(validLinkIds, t.linkId)
  )

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
 * Apply timeline cleanup to state
 * Returns the new state and cleanup result
 * 
 * Cleanup strategy:
 * 1. Remove timeline items with linkIds that don't exist in any hotspot (orphaned)
 * 2. Keep only the LAST timeline item for each unique linkId (removes duplicates from edits)
 */
let applyCleanup = (state: state): (state, cleanupResult) => {
  let timelineItemsBefore = Belt.Array.length(state.timeline)
  
  // Collect all valid linkIds from all scenes
  let validLinkIds = collectValidLinkIds(state.inventory)
  
  // Step 1: Remove orphaned items (linkIds not in any hotspot)
  let afterOrphanRemoval = state.timeline->Belt.Array.keep(t =>
    Belt.Set.String.has(validLinkIds, t.linkId)
  )
  
  // Step 2: Remove duplicates - keep only the LAST item for each linkId
  // We do this by reversing, keeping first occurrence of each linkId, then reversing back
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
  
  let timelineItemsAfter = Belt.Array.length(dedupedTimeline)
  let removedCount = timelineItemsBefore - timelineItemsAfter
  
  // Collect removed linkIds for reporting
  let removedLinkIds =
    state.timeline
    ->Belt.Array.keep(t => !Belt.Array.some(dedupedTimeline, dt => dt.id == t.id))
    ->Belt.Array.map(t => t.linkId)
  
  // Clear active timeline step if it was removed
  let activeTimelineStepId = switch state.activeTimelineStepId {
  | Some(stepId) =>
    let stillExists = dedupedTimeline->Belt.Array.some(t => t.id == stepId)
    stillExists ? Some(stepId) : None
  | None => None
  }
  
  let result = {
    timelineItemsBefore,
    timelineItemsAfter,
    removedCount,
    removedLinkIds,
  }
  
  (
    {...state, timeline: dedupedTimeline, activeTimelineStepId},
    result,
  )
}
