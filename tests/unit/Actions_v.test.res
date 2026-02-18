open Vitest
open Actions
open Types

describe("Actions", _ => {
  test("SetPreloadingScene matches string representation", t => {
    t->expect(actionToString(SetPreloadingScene(5)))->Expect.toBe("SetPreloadingScene(5)")
  })

  test("UpdateLinkDraft matches string representation", t => {
    let dummyDraft: linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 0.0,
      intermediatePoints: None,
    }
    t->expect(actionToString(UpdateLinkDraft(dummyDraft)))->Expect.toBe("UpdateLinkDraft")
  })

  test("StartLinking matches string representation", t => {
    let dummyDraft: linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 0.0,
      intermediatePoints: None,
    }
    t->expect(actionToString(StartLinking(Some(dummyDraft))))->Expect.toBe("StartLinking")
  })

  test("StopLinking matches string representation", t => {
    t->expect(actionToString(StopLinking))->Expect.toBe("StopLinking")
  })

  test("SetIsTeasing matches string representation", t => {
    t->expect(actionToString(SetIsTeasing(true)))->Expect.toBe("SetIsTeasing(true)")
  })

  test("SetTourName matches string representation", t => {
    t->expect(actionToString(SetTourName("My Tour")))->Expect.toBe("SetTourName(My Tour)")
  })

  test("AddScenes matches string representation", t => {
    t->expect(actionToString(AddScenes([JSON.Encode.null])))->Expect.toBe("AddScenes(1)")
  })

  test("SetActiveScene matches string representation", t => {
    t->expect(actionToString(SetActiveScene(2, 0.0, 0.0, None)))->Expect.toBe("SetActiveScene(2)")
  })

  test("AddHotspot matches string representation", t => {
    let dummyHotspot: hotspot = {
      linkId: "1",
      yaw: 0.0,
      pitch: 0.0,
      target: "target",
      targetSceneId: None,
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
      isAutoForward: None,
    }
    t->expect(actionToString(AddHotspot(1, dummyHotspot)))->Expect.toBe("AddHotspot(1)")
  })

  test("RemoveHotspot matches string representation", t => {
    t->expect(actionToString(RemoveHotspot(1, 2)))->Expect.toBe("RemoveHotspot(1, 2)")
  })

  test("ReorderScenes matches string representation", t => {
    t->expect(actionToString(ReorderScenes(0, 1)))->Expect.toBe("ReorderScenes(0, 1)")
  })

  test("ClearHotspots matches string representation", t => {
    t->expect(actionToString(ClearHotspots(3)))->Expect.toBe("ClearHotspots(3)")
  })

  test("DeleteScene matches string representation", t => {
    t->expect(actionToString(DeleteScene(4)))->Expect.toBe("DeleteScene(4)")
  })

  test("RemoveDeletedSceneId matches string representation", t => {
    t->expect(actionToString(RemoveDeletedSceneId("id1")))->Expect.toBe("RemoveDeletedSceneId(id1)")
  })

  test("SyncSceneNames matches string representation", t => {
    t->expect(actionToString(SyncSceneNames))->Expect.toBe("SyncSceneNames")
  })

  test("ApplyLazyRename matches string representation", t => {
    t
    ->expect(actionToString(ApplyLazyRename(1, "New Name")))
    ->Expect.toBe("ApplyLazyRename(1, New Name)")
  })

  test("UpdateSceneMetadata matches string representation", t => {
    t
    ->expect(actionToString(UpdateSceneMetadata(2, JSON.Encode.null)))
    ->Expect.toBe("UpdateSceneMetadata(2)")
  })

  test("UpdateHotspotTargetView matches string representation", t => {
    t
    ->expect(actionToString(UpdateHotspotTargetView(1, 2, 0.0, 0.0, 0.0)))
    ->Expect.toBe("UpdateHotspotTargetView(1, 2)")
  })

  test("UpdateHotspotReturnView matches string representation", t => {
    t
    ->expect(actionToString(UpdateHotspotReturnView(1, 2, 0.0, 0.0, 0.0)))
    ->Expect.toBe("UpdateHotspotReturnView(1, 2)")
  })

  test("ToggleHotspotReturnLink matches string representation", t => {
    t
    ->expect(actionToString(ToggleHotspotReturnLink(1, 2)))
    ->Expect.toBe("ToggleHotspotReturnLink(1, 2)")
  })

  test("AddToTimeline matches string representation", t => {
    t->expect(actionToString(AddToTimeline(JSON.Encode.null)))->Expect.toBe("AddToTimeline")
  })

  test("SetActiveTimelineStep matches string representation", t => {
    t
    ->expect(actionToString(SetActiveTimelineStep(Some("step1"))))
    ->Expect.toBe("SetActiveTimelineStep(step1)")
    t
    ->expect(actionToString(SetActiveTimelineStep(None)))
    ->Expect.toBe("SetActiveTimelineStep(None)")
  })

  test("RemoveFromTimeline matches string representation", t => {
    t->expect(actionToString(RemoveFromTimeline("id1")))->Expect.toBe("RemoveFromTimeline(id1)")
  })

  test("ReorderTimeline matches string representation", t => {
    t->expect(actionToString(ReorderTimeline(1, 2)))->Expect.toBe("ReorderTimeline(1, 2)")
  })

  test("UpdateTimelineStep matches string representation", t => {
    t
    ->expect(actionToString(UpdateTimelineStep("id1", JSON.Encode.null)))
    ->Expect.toBe("UpdateTimelineStep(id1)")
  })

  test("LoadProject matches string representation", t => {
    t->expect(actionToString(LoadProject(JSON.Encode.null)))->Expect.toBe("LoadProject")
  })

  test("Reset matches string representation", t => {
    t->expect(actionToString(Reset))->Expect.toBe("Reset")
  })

  test("SetSimulationMode matches string representation", t => {
    t->expect(actionToString(SetSimulationMode(true)))->Expect.toBe("SetSimulationMode(true)")
  })

  test("SetNavigationStatus matches string representation", t => {
    t->expect(actionToString(SetNavigationStatus(Idle)))->Expect.toBe("SetNavigationStatus")
  })

  test("SetIncomingLink matches string representation", t => {
    t->expect(actionToString(SetIncomingLink(None)))->Expect.toBe("SetIncomingLink")
  })

  test("ResetAutoForwardChain matches string representation", t => {
    t->expect(actionToString(ResetAutoForwardChain))->Expect.toBe("ResetAutoForwardChain")
  })

  test("AddToAutoForwardChain matches string representation", t => {
    t->expect(actionToString(AddToAutoForwardChain(5)))->Expect.toBe("AddToAutoForwardChain(5)")
  })

  test("SetPendingReturnSceneName matches string representation", t => {
    t
    ->expect(actionToString(SetPendingReturnSceneName(Some("scene"))))
    ->Expect.toBe("SetPendingReturnSceneName(scene)")
    t
    ->expect(actionToString(SetPendingReturnSceneName(None)))
    ->Expect.toBe("SetPendingReturnSceneName(None)")
  })

  test("IncrementJourneyId matches string representation", t => {
    t->expect(actionToString(IncrementJourneyId))->Expect.toBe("IncrementJourneyId")
  })

  test("SetCurrentJourneyId matches string representation", t => {
    t->expect(actionToString(SetCurrentJourneyId(10)))->Expect.toBe("SetCurrentJourneyId(10)")
  })

  test("NavigationCompleted matches string representation", t => {
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
    t->expect(actionToString(NavigationCompleted(dummyJourney)))->Expect.toBe("NavigationCompleted")
  })

  test("SetExifReport matches string representation", t => {
    t->expect(actionToString(SetExifReport(JSON.Encode.null)))->Expect.toBe("SetExifReport")
  })

  test("StartAutoPilot matches string representation", t => {
    t->expect(actionToString(StartAutoPilot(1, true)))->Expect.toBe("StartAutoPilot")
  })

  test("StopAutoPilot matches string representation", t => {
    t->expect(actionToString(StopAutoPilot))->Expect.toBe("StopAutoPilot")
  })

  test("AddVisitedScene matches string representation", t => {
    t->expect(actionToString(AddVisitedScene(3)))->Expect.toBe("AddVisitedScene")
  })

  test("ClearVisitedScenes matches string representation", t => {
    t->expect(actionToString(ClearVisitedScenes))->Expect.toBe("ClearVisitedScenes")
  })

  test("SetStoppingOnArrival matches string representation", t => {
    t->expect(actionToString(SetStoppingOnArrival(true)))->Expect.toBe("SetStoppingOnArrival")
  })

  test("SetSkipAutoForward matches string representation", t => {
    t->expect(actionToString(SetSkipAutoForward(true)))->Expect.toBe("SetSkipAutoForward")
  })

  test("UpdateAdvanceTime matches string representation", t => {
    t->expect(actionToString(UpdateAdvanceTime(5.0)))->Expect.toBe("UpdateAdvanceTime")
  })

  test("SetPendingAdvance matches string representation", t => {
    t->expect(actionToString(SetPendingAdvance(Some(2))))->Expect.toBe("SetPendingAdvance")
  })

  test("SetSessionId matches string representation", t => {
    t->expect(actionToString(SetSessionId("session-123")))->Expect.toBe("SetSessionId(session-123)")
  })
})
