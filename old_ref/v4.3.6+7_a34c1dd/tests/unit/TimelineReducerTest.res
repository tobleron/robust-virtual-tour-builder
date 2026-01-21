open Types
open Actions

let run = () => {
  Console.log("Running TimelineReducer tests...")

  let initialState = State.initialState
  let state = initialState

  // --- Test AddToTimeline ---
  let itemJson = JSON.Encode.object(
    Dict.fromArray([
      ("id", JSON.Encode.string("step1")),
      ("linkId", JSON.Encode.string("link1")),
      ("sceneId", JSON.Encode.string("scene1")),
      ("targetScene", JSON.Encode.string("scene2")),
      ("transition", JSON.Encode.string("fade")),
      ("duration", JSON.Encode.int(1000)),
    ]),
  )

  let actionAdd = AddToTimeline(itemJson)
  let resultAdd = TimelineReducer.reduce(state, actionAdd)

  let stateWithItem = switch resultAdd {
  | Some(ns) =>
    assert(Array.length(ns.timeline) == 1)
    let item = Array.getUnsafe(ns.timeline, 0)
    assert(item.id == "step1")
    assert(item.transition == "fade")
    Console.log("✓ AddToTimeline passed")
    ns
  | None =>
    Console.error("✗ AddToTimeline failed: returned None")
    state
  }

  // --- Test SetActiveTimelineStep ---
  let actionSetActive = SetActiveTimelineStep(Some("step1"))
  let resultSetActive = TimelineReducer.reduce(stateWithItem, actionSetActive)

  switch resultSetActive {
  | Some(ns) =>
    assert(ns.activeTimelineStepId == Some("step1"))
    Console.log("✓ SetActiveTimelineStep passed")
  | None => Console.error("✗ SetActiveTimelineStep failed")
  }

  // --- Test UpdateTimelineStep ---
  let updateJson = JSON.Encode.object(
    Dict.fromArray([
      ("transition", JSON.Encode.string("crossfade")),
      ("duration", JSON.Encode.int(2000)),
    ]),
  )

  let actionUpdate = UpdateTimelineStep("step1", updateJson)
  let resultUpdate = TimelineReducer.reduce(stateWithItem, actionUpdate)

  let stateUpdated = switch resultUpdate {
  | Some(ns) =>
    let item = Array.getUnsafe(ns.timeline, 0)
    assert(item.transition == "crossfade")
    assert(item.duration == 2000)
    Console.log("✓ UpdateTimelineStep passed")
    ns
  | None =>
    Console.error("✗ UpdateTimelineStep failed")
    stateWithItem
  }

  // --- Test ReorderTimeline ---
  // Add another item first
  let item2Json = JSON.Encode.object(
    Dict.fromArray([
      ("id", JSON.Encode.string("step2")),
      ("linkId", JSON.Encode.string("link2")),
      ("sceneId", JSON.Encode.string("scene2")),
      ("targetScene", JSON.Encode.string("scene3")),
      ("transition", JSON.Encode.string("fade")),
      ("duration", JSON.Encode.int(1000)),
    ]),
  )

  let stateWithTwoItems = switch TimelineReducer.reduce(stateUpdated, AddToTimeline(item2Json)) {
  | Some(ns) => ns
  | None => stateUpdated
  }

  assert(Array.length(stateWithTwoItems.timeline) == 2)
  assert(Array.getUnsafe(stateWithTwoItems.timeline, 0).id == "step1")
  assert(Array.getUnsafe(stateWithTwoItems.timeline, 1).id == "step2")

  let actionReorder = ReorderTimeline(0, 1) // Move first to second
  let resultReorder = TimelineReducer.reduce(stateWithTwoItems, actionReorder)

  let stateReordered = switch resultReorder {
  | Some(ns) =>
    assert(Array.getUnsafe(ns.timeline, 0).id == "step2")
    assert(Array.getUnsafe(ns.timeline, 1).id == "step1")
    Console.log("✓ ReorderTimeline passed")
    ns
  | None =>
    Console.error("✗ ReorderTimeline failed")
    stateWithTwoItems
  }

  // --- Test RemoveFromTimeline ---
  let actionRemove = RemoveFromTimeline("step1")
  let resultRemove = TimelineReducer.reduce(stateReordered, actionRemove)

  switch resultRemove {
  | Some(ns) =>
    assert(Array.length(ns.timeline) == 1)
    assert(Array.getUnsafe(ns.timeline, 0).id == "step2")
    Console.log("✓ RemoveFromTimeline passed")
  | None => Console.error("✗ RemoveFromTimeline failed")
  }

  // --- Test Fallthrough ---
  let actionUnknown = Obj.magic("UnknownAction")
  let resultUnknown = TimelineReducer.reduce(state, actionUnknown)
  assert(resultUnknown == None)
  Console.log("✓ Fallthrough passed")

  Console.log("TimelineReducer tests completed.")
}
