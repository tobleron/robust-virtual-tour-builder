open Vitest
open Types

describe("Types", () => {
  test("should define file correctly", t => {
    let f = Url("test.jpg")
    t->expect(f)->Expect.toEqual(Url("test.jpg"))
  })

  test("should define linkInfo correctly", t => {
    let info: linkInfo = {
      sceneIndex: 1,
      hotspotIndex: 2,
    }
    t->expect(info.sceneIndex)->Expect.toBe(1)
    t->expect(info.hotspotIndex)->Expect.toBe(2)
  })

  test("should define pathPoint correctly", t => {
    let p: pathPoint = {
      yaw: 10.0,
      pitch: 20.0,
    }
    t->expect(p.yaw)->Expect.toBe(10.0)
    t->expect(p.pitch)->Expect.toBe(20.0)
  })

  test("should define pathSegment correctly", t => {
    let p1 = {yaw: 0.0, pitch: 0.0}
    let p2 = {yaw: 10.0, pitch: 5.0}
    let s: pathSegment = {
      dist: 11.18,
      yawDiff: 10.0,
      pitchDiff: 5.0,
      p1,
      p2,
    }
    t->expect(s.dist)->Expect.toBe(11.18)
    t->expect(s.p1)->Expect.toEqual(p1)
  })

  test("should define pathData correctly", t => {
    let p1 = {yaw: 0.0, pitch: 0.0}
    let p2 = {yaw: 10.0, pitch: 5.0}
    let s = {dist: 11.18, yawDiff: 10.0, pitchDiff: 5.0, p1, p2}
    let pd: pathData = {
      startPitch: 0.0,
      startYaw: 0.0,
      startHfov: 80.0,
      targetPitchForPan: 5.0,
      targetYawForPan: 10.0,
      targetHfovForPan: 80.0,
      totalPathDistance: 11.18,
      segments: [s],
      waypoints: [p1, p2],
      panDuration: 1.0,
      arrivalYaw: 10.0,
      arrivalPitch: 5.0,
      arrivalHfov: 80.0,
    }
    t->expect(pd.totalPathDistance)->Expect.toBe(11.18)
    t->expect(pd.segments->Belt.Array.length)->Expect.toBe(1)
  })

  test("should define journeyData correctly", t => {
    let jd: journeyData = {
      journeyId: 1,
      targetIndex: 1,
      sourceIndex: 0,
      hotspotIndex: 0,
      arrivalYaw: 0.0,
      arrivalPitch: 0.0,
      arrivalHfov: 80.0,
      previewOnly: false,
      pathData: None,
    }
    t->expect(jd.journeyId)->Expect.toBe(1)
    t->expect(jd.targetIndex)->Expect.toBe(1)
  })

  test("should define navigationStatus correctly", t => {
    let idle = Idle
    t->expect(idle)->Expect.toEqual(Idle)

    let navigating = Navigating({
      journeyId: 1,
      targetIndex: 1,
      sourceIndex: 0,
      hotspotIndex: 0,
      arrivalYaw: 0.0,
      arrivalPitch: 0.0,
      arrivalHfov: 0.0,
      previewOnly: false,
      pathData: None,
    })

    t->expect(navigating)->Expect.toEqual(navigating)
  })

  test("should define transition correctly", t => {
    let tr: transition = {
      type_: Fade,
      targetHotspotIndex: 1,
      fromSceneName: None,
    }
    t->expect(tr.type_)->Expect.toEqual(Fade)
    t->expect(tr.targetHotspotIndex)->Expect.toBe(1)
  })

  test("should define simulationStatus correctly", t => {
    t->expect(Idle)->Expect.toEqual(Idle)
    t->expect(Running)->Expect.toEqual(Running)
    t->expect(Stopping)->Expect.toEqual(Stopping)
    t->expect(Paused)->Expect.toEqual(Paused)
  })

  test("should define simulationState correctly", t => {
    let ss: simulationState = {
      status: Running,
      visitedScenes: [1, 2],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: true,
      lastAdvanceTime: 12345.6,
      pendingAdvanceId: Some(1),
      autoPilotJourneyId: 42,
    }
    t->expect(ss.status)->Expect.toEqual(Running)
    t->expect(ss.visitedScenes)->Expect.toEqual([1, 2])
  })

  test("should define viewFrame correctly", t => {
    let vf: viewFrame = {
      yaw: 1.0,
      pitch: 2.0,
      hfov: 80.0,
    }
    t->expect(vf.yaw)->Expect.toBe(1.0)
    t->expect(vf.hfov)->Expect.toBe(80.0)
  })

  test("should define linkDraft correctly", t => {
    let ld: linkDraft = {
      pitch: 0.0,
      yaw: 0.0,
      camPitch: 0.0,
      camYaw: 0.0,
      camHfov: 80.0,
      intermediatePoints: None,
    }
    t->expect(ld.camHfov)->Expect.toBe(80.0)
  })

  test("should define hotspot correctly", t => {
    let h: hotspot = {
      linkId: "link-1",
      yaw: 0.0,
      pitch: 0.0,
      target: "scene-2",
      targetSceneId: None,
      targetYaw: Some(10.0),
      targetPitch: None,
      targetHfov: None,
      startYaw: None,
      startPitch: None,
      startHfov: None,
      isReturnLink: Some(false),
      viewFrame: None,
      returnViewFrame: None,
      waypoints: None,
      displayPitch: None,
      transition: None,
      duration: None,
    }
    t->expect(h.linkId)->Expect.toBe("link-1")
    t->expect(h.target)->Expect.toBe("scene-2")
  })

  test("should define scene correctly", t => {
    let s: scene = {
      id: "1",
      name: "Scene 1",
      file: Url("s1.jpg"),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "Room",
      floor: "1",
      label: "Living Room",
      quality: None,
      colorGroup: None,
      _metadataSource: "test",
      categorySet: true,
      labelSet: true,
      isAutoForward: false,
    }
    t->expect(s.name)->Expect.toBe("Scene 1")
    t->expect(s.category)->Expect.toBe("Room")
  })

  test("should define timelineItem correctly", t => {
    let ti: timelineItem = {
      id: "step-1",
      linkId: "link-1",
      sceneId: "scene-1",
      targetScene: "scene-2",
      transition: "fade",
      duration: 1000,
    }
    t->expect(ti.id)->Expect.toBe("step-1")
    t->expect(ti.duration)->Expect.toBe(1000)
  })

  test("should define uploadReport correctly", t => {
    let ur: uploadReport = {
      success: ["img1.jpg"],
      skipped: ["img2.jpg"],
    }
    t->expect(ur.success)->Expect.toEqual(["img1.jpg"])
    t->expect(ur.skipped)->Expect.toEqual(["img2.jpg"])
  })

  test("should define state correctly", t => {
    let st: state = {
      tourName: "Test Tour",
      scenes: [],
      inventory: Belt.Map.String.empty,
      sceneOrder: [],
      activeIndex: 0,
      activeYaw: 0.0,
      activePitch: 0.0,
      isLinking: false,
      transition: {
        type_: Fade,
        targetHotspotIndex: -1,
        fromSceneName: None,
      },
      appMode: Initializing,
      exifReport: None,
      linkDraft: None,
      preloadingSceneIndex: -1,
      isTeasing: false,
      deletedSceneIds: [],
      timeline: [],
      activeTimelineStepId: None,
      navigationState: {
        navigation: Idle,
        navigationFsm: IdleFsm,
        incomingLink: None,
        autoForwardChain: [],
        currentJourneyId: 0,
      },
      simulation: {
        status: Idle,
        visitedScenes: [],
        stoppingOnArrival: false,
        skipAutoForwardGlobal: false,
        lastAdvanceTime: 0.0,
        pendingAdvanceId: None,
        autoPilotJourneyId: 0,
      },
      pendingReturnSceneName: None,
      lastUsedCategory: "",
      sessionId: None,
      logo: None,
      structuralRevision: 0,
    }
    t->expect(st.tourName)->Expect.toBe("Test Tour")
    t->expect(st.activeIndex)->Expect.toBe(0)
  })
})
