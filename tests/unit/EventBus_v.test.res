// @efficiency: infra-adapter
open Vitest
open EventBus
open Types

describe("EventBus", _ => {
  test("Basic subscription and dispatch", t => {
    let callCount = ref(0)
    let receivedEvent = ref(None)

    let unsubscribe = subscribe(
      evt => {
        callCount := callCount.contents + 1
        receivedEvent := Some(evt)
      },
    )

    dispatch(NavCancelled)

    t->expect(callCount.contents)->Expect.toBe(1)
    unsubscribe()
  })

  test("Unsubscribe prevents further events", t => {
    let callCount = ref(0)
    let unsubscribe = subscribe(
      _evt => {
        callCount := callCount.contents + 1
      },
    )

    dispatch(NavCancelled)
    unsubscribe()
    dispatch(NavCancelled)

    t->expect(callCount.contents)->Expect.toBe(1)
  })

  test("Multiple subscribers receive events", t => {
    let callCount1 = ref(0)
    let callCount2 = ref(0)
    let callCount3 = ref(0)

    let unsub1 = subscribe(_evt => callCount1 := callCount1.contents + 1)
    let unsub2 = subscribe(_evt => callCount2 := callCount2.contents + 1)
    let unsub3 = subscribe(_evt => callCount3 := callCount3.contents + 1)

    dispatch(ClearSimUi)

    t->expect(callCount1.contents)->Expect.toBe(1)
    t->expect(callCount2.contents)->Expect.toBe(1)
    t->expect(callCount3.contents)->Expect.toBe(1)

    unsub1()
    unsub2()
    unsub3()
  })

  test("Selective unsubscribe works correctly", t => {
    let callCount1 = ref(0)
    let callCount2 = ref(0)

    let unsub1 = subscribe(_evt => callCount1 := callCount1.contents + 1)
    let unsub2 = subscribe(_evt => callCount2 := callCount2.contents + 1)

    dispatch(LinkPreviewEnd)
    unsub1()
    dispatch(LinkPreviewEnd)

    t->expect(callCount1.contents)->Expect.toBe(1)
    t->expect(callCount2.contents)->Expect.toBe(2)

    unsub2()
  })

  test("Error in callback doesn't affect other subscribers", t => {
    let callCount1 = ref(0)
    let callCount2 = ref(0)

    let unsub1 = subscribe(
      _evt => {
        callCount1 := callCount1.contents + 1
        JsError.throwWithMessage("Intentional test error")
      },
    )

    let unsub2 = subscribe(
      _evt => {
        callCount2 := callCount2.contents + 1
      },
    )

    // Dispatch should not throw
    dispatch(NavCancelled)

    t->expect(callCount1.contents)->Expect.toBe(1)
    t->expect(callCount2.contents)->Expect.toBe(1)

    unsub1()
    unsub2()
  })

  test("Different event types dispatched correctly", t => {
    let receivedEvents = ref([])
    let unsub = subscribe(
      evt => {
        receivedEvents := Belt.Array.concat(receivedEvents.contents, [evt])
      },
    )

    dispatch(NavCancelled)
    dispatch(ClearSimUi)
    dispatch(LinkPreviewEnd)
    dispatch(CloseModal)

    t->expect(Belt.Array.length(receivedEvents.contents))->Expect.toBe(4)
    unsub()
  })

  test("NavProgress event with payload", t => {
    let receivedProgress = ref(None)
    let unsub = subscribe(
      evt => {
        switch evt {
        | NavProgress(progress) => receivedProgress := Some(progress)
        | _ => ()
        }
      },
    )

    dispatch(NavProgress(0.75))

    t->expect(receivedProgress.contents)->Expect.toBe(Some(0.75))
    unsub()
  })

  test("ShowNotification with different severity levels", t => {
    let receivedNotifications = ref([])
    let unsub = subscribe(
      evt => {
        switch evt {
        | ShowNotification(msg, severity) =>
          receivedNotifications :=
            Belt.Array.concat(receivedNotifications.contents, [(msg, severity)])
        | _ => ()
        }
      },
    )

    dispatch(ShowNotification("Info message", #Info))
    dispatch(ShowNotification("Success message", #Success))
    dispatch(ShowNotification("Error message", #Error))
    dispatch(ShowNotification("Warning message", #Warning))

    t->expect(Belt.Array.length(receivedNotifications.contents))->Expect.toBe(4)
    unsub()
  })

  test("SceneArrived event with scene name", t => {
    let receivedSceneName = ref(None)
    let unsub = subscribe(
      evt => {
        switch evt {
        | SceneArrived(sceneName) => receivedSceneName := Some(sceneName)
        | _ => ()
        }
      },
    )

    dispatch(SceneArrived("living-room"))

    t->expect(receivedSceneName.contents)->Expect.toBe(Some("living-room"))
    unsub()
  })

  test("LinkPreviewStart event with URL", t => {
    let receivedUrl = ref(None)
    let unsub = subscribe(
      evt => {
        switch evt {
        | LinkPreviewStart(url) => receivedUrl := Some(url)
        | _ => ()
        }
      },
    )

    dispatch(LinkPreviewStart("https://example.com/scene"))

    t->expect(receivedUrl.contents)->Expect.toBe(Some("https://example.com/scene"))
    unsub()
  })

  test("NavStart event with complex payload", t => {
    let receivedPayload = ref(None)
    let unsub = subscribe(
      evt => {
        switch evt {
        | NavStart(payload) => receivedPayload := Some(payload)
        | _ => ()
        }
      },
    )

    let testPathData: Types.pathData = {
      startPitch: 0.0,
      startYaw: 0.0,
      startHfov: 90.0,
      targetPitchForPan: 10.0,
      targetYawForPan: 45.0,
      targetHfovForPan: 90.0,
      totalPathDistance: 100.0,
      segments: [],
      waypoints: [],
      panDuration: 1.5,
      arrivalYaw: 45.0,
      arrivalPitch: 10.0,
      arrivalHfov: 90.0,
    }

    let testPayload: navStartPayload = {
      journeyId: 42,
      targetIndex: 5,
      sourceIndex: 3,
      hotspotIndex: 1,
      previewOnly: false,
      pathData: testPathData,
    }

    dispatch(NavStart(testPayload))

    switch receivedPayload.contents {
    | Some(payload) => {
        t->expect(payload.journeyId)->Expect.toBe(42)
        t->expect(payload.targetIndex)->Expect.toBe(5)
      }
    | None => t->expect(true)->Expect.toBe(false)
    }

    unsub()
  })

  test("ShowModal event with modal config", t => {
    let receivedModalConfig = ref(None)
    let unsub = subscribe(
      evt => {
        switch evt {
        | ShowModal(config) => receivedModalConfig := Some(config)
        | _ => ()
        }
      },
    )

    let testModalConfig: modalConfig = {
      title: "Test Modal",
      description: Some("This is a test"),
      content: None,
      buttons: [],
      icon: Some("info"),
      allowClose: Some(true),
      onClose: None,
      className: None,
    }
    dispatch(ShowModal(testModalConfig))

    switch receivedModalConfig.contents {
    | Some(config) => t->expect(config.title)->Expect.toBe("Test Modal")
    | None => t->expect(true)->Expect.toBe(false)
    }

    unsub()
  })

  test("Dispatching with no subscribers doesn't cause errors", t => {
    // Should not throw
    dispatch(NavCancelled)
    dispatch(ClearSimUi)
    dispatch(NavProgress(0.5))
    // If we reached here, pass
    t->expect(true)->Expect.toBe(true)
  })

  test("Resubscribe after unsubscribe works", t => {
    let callCount = ref(0)
    let unsub1 = subscribe(_evt => callCount := callCount.contents + 1)
    dispatch(NavCancelled)
    unsub1()

    let unsub2 = subscribe(_evt => callCount := callCount.contents + 1)
    dispatch(NavCancelled)

    t->expect(callCount.contents)->Expect.toBe(2)
    unsub2()
  })
})
