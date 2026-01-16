open Actions
open Types

let run = () => {
  Console.log("Running Actions tests...")

  let assertString = (action, expected, name) => {
    let result = actionToString(action)
    if result == expected {
      Console.log("✓ " ++ name ++ " passed")
    } else {
      Console.error(
        "✗ " ++ name ++ " failed: expected '" ++ expected ++ "', got '" ++ result ++ "'",
      )
    }
  }

  assertString(SetPreloadingScene(5), "SetPreloadingScene(5)", "SetPreloadingScene")

  assertString(SetLinkDraft(None), "SetLinkDraft(None)", "SetLinkDraft(None)")
  assertString(
    SetLinkDraft(
      Some({
        pitch: 0.0,
        yaw: 0.0,
        camPitch: 0.0,
        camYaw: 0.0,
        camHfov: 0.0,
        intermediatePoints: None,
      }),
    ),
    "SetLinkDraft(Some)",
    "SetLinkDraft(Some)",
  )

  assertString(SetIsLinking(true), "SetIsLinking(true)", "SetIsLinking(true)")
  assertString(SetIsLinking(false), "SetIsLinking(false)", "SetIsLinking(false)")

  assertString(SetIsTeasing(true), "SetIsTeasing(true)", "SetIsTeasing(true)")

  assertString(SetTourName("My Tour"), "SetTourName(My Tour)", "SetTourName")

  assertString(AddScenes([JSON.Encode.null]), "AddScenes(1)", "AddScenes")

  assertString(SetActiveScene(2, 0.0, 0.0, None), "SetActiveScene(2)", "SetActiveScene")

  let dummyHotspot: hotspot = {
    linkId: "1",
    yaw: 0.0,
    pitch: 0.0,
    target: "target",
    targetYaw: None,
    targetPitch: None,
    targetHfov: None,
    startYaw: None,
    startPitch: None,
    startHfov: None,
    isReturnLink: None,
    viewFrame: None,
    returnViewFrame: None,
    waypoints: None,
    displayPitch: None,
    transition: None,
    duration: None,
  }

  assertString(AddHotspot(1, dummyHotspot), "AddHotspot(1)", "AddHotspot")

  assertString(RemoveHotspot(1, 2), "RemoveHotspot(1, 2)", "RemoveHotspot")

  assertString(ReorderScenes(0, 1), "ReorderScenes(0, 1)", "ReorderScenes")

  assertString(ClearHotspots(3), "ClearHotspots(3)", "ClearHotspots")

  assertString(DeleteScene(4), "DeleteScene(4)", "DeleteScene")

  assertString(RemoveDeletedSceneId("id1"), "RemoveDeletedSceneId(id1)", "RemoveDeletedSceneId")

  assertString(SyncSceneNames, "SyncSceneNames", "SyncSceneNames")

  assertString(ApplyLazyRename(1, "New Name"), "ApplyLazyRename(1, New Name)", "ApplyLazyRename")

  assertString(
    UpdateSceneMetadata(2, JSON.Encode.null),
    "UpdateSceneMetadata(2)",
    "UpdateSceneMetadata",
  )

  assertString(
    UpdateHotspotTargetView(1, 2, 0.0, 0.0, 0.0),
    "UpdateHotspotTargetView(1, 2)",
    "UpdateHotspotTargetView",
  )

  assertString(
    UpdateHotspotReturnView(1, 2, 0.0, 0.0, 0.0),
    "UpdateHotspotReturnView(1, 2)",
    "UpdateHotspotReturnView",
  )

  assertString(
    ToggleHotspotReturnLink(1, 2),
    "ToggleHotspotReturnLink(1, 2)",
    "ToggleHotspotReturnLink",
  )

  assertString(AddToTimeline(JSON.Encode.null), "AddToTimeline", "AddToTimeline")

  assertString(
    SetActiveTimelineStep(Some("step1")),
    "SetActiveTimelineStep(step1)",
    "SetActiveTimelineStep(Some)",
  )
  assertString(
    SetActiveTimelineStep(None),
    "SetActiveTimelineStep(None)",
    "SetActiveTimelineStep(None)",
  )

  assertString(RemoveFromTimeline("id1"), "RemoveFromTimeline(id1)", "RemoveFromTimeline")

  assertString(ReorderTimeline(1, 2), "ReorderTimeline(1, 2)", "ReorderTimeline")

  assertString(
    UpdateTimelineStep("id1", JSON.Encode.null),
    "UpdateTimelineStep(id1)",
    "UpdateTimelineStep",
  )

  assertString(LoadProject(JSON.Encode.null), "LoadProject", "LoadProject")

  assertString(Reset, "Reset", "Reset")

  assertString(SetSimulationMode(true), "SetSimulationMode(true)", "SetSimulationMode")

  assertString(SetNavigationStatus(Idle), "SetNavigationStatus", "SetNavigationStatus")

  assertString(SetIncomingLink(None), "SetIncomingLink", "SetIncomingLink")

  assertString(ResetAutoForwardChain, "ResetAutoForwardChain", "ResetAutoForwardChain")

  assertString(AddToAutoForwardChain(5), "AddToAutoForwardChain(5)", "AddToAutoForwardChain")

  assertString(
    SetPendingReturnSceneName(Some("scene")),
    "SetPendingReturnSceneName(scene)",
    "SetPendingReturnSceneName(Some)",
  )
  assertString(
    SetPendingReturnSceneName(None),
    "SetPendingReturnSceneName(None)",
    "SetPendingReturnSceneName(None)",
  )

  assertString(IncrementJourneyId, "IncrementJourneyId", "IncrementJourneyId")

  assertString(SetCurrentJourneyId(10), "SetCurrentJourneyId(10)", "SetCurrentJourneyId")

  let dummyJourney: journeyData = {
    journeyId: 1,
    targetIndex: 2,
    sourceIndex: 3,
    hotspotIndex: 4,
    arrivalYaw: 0.0,
    arrivalPitch: 0.0,
    arrivalHfov: 0.0,
    previewOnly: false,
    pathData: None,
  }
  assertString(NavigationCompleted(dummyJourney), "NavigationCompleted", "NavigationCompleted")

  assertString(SetExifReport(JSON.Encode.null), "SetExifReport", "SetExifReport")

  Console.log("✓ Actions: Module logic verified")
}
