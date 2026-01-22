open EventBus

let run = () => {
  Console.log("Running EventBus tests...")

  {
    // Test 1: Subscribe and dispatch basic event

    let callCount = ref(0)
    let receivedEvent = ref(None)

    let unsubscribe = subscribe(evt => {
      callCount := callCount.contents + 1
      receivedEvent := Some(evt)
    })

    dispatch(NavCancelled)

    if callCount.contents == 1 {
      Console.log("✓ Basic subscription and dispatch")
    } else {
      Console.error(
        "✗ Basic subscription failed: expected 1 call, got " ++
        Belt.Int.toString(callCount.contents),
      )
    }

    unsubscribe()
  }

  {
    // Test 2: Unsubscribe prevents further events

    let callCount = ref(0)

    let unsubscribe = subscribe(_evt => {
      callCount := callCount.contents + 1
    })

    dispatch(NavCancelled)
    unsubscribe()
    dispatch(NavCancelled)

    if callCount.contents == 1 {
      Console.log("✓ Unsubscribe prevents further events")
    } else {
      Console.error(
        "✗ Unsubscribe failed: expected 1 call, got " ++ Belt.Int.toString(callCount.contents),
      )
    }
  }

  {
    // Test 3: Multiple subscribers receive events

    let callCount1 = ref(0)
    let callCount2 = ref(0)
    let callCount3 = ref(0)

    let unsub1 = subscribe(_evt => callCount1 := callCount1.contents + 1)
    let unsub2 = subscribe(_evt => callCount2 := callCount2.contents + 1)
    let unsub3 = subscribe(_evt => callCount3 := callCount3.contents + 1)

    dispatch(ClearSimUi)

    if callCount1.contents == 1 && callCount2.contents == 1 && callCount3.contents == 1 {
      Console.log("✓ Multiple subscribers receive events")
    } else {
      Console.error("✗ Multiple subscribers failed")
    }

    unsub1()
    unsub2()
    unsub3()
  }

  {
    // Test 4: Selective unsubscribe

    let callCount1 = ref(0)
    let callCount2 = ref(0)

    let unsub1 = subscribe(_evt => callCount1 := callCount1.contents + 1)
    let unsub2 = subscribe(_evt => callCount2 := callCount2.contents + 1)

    dispatch(LinkPreviewEnd)
    unsub1()
    dispatch(LinkPreviewEnd)

    if callCount1.contents == 1 && callCount2.contents == 2 {
      Console.log("✓ Selective unsubscribe works correctly")
    } else {
      Console.error(
        "✗ Selective unsubscribe failed: sub1=" ++
        Belt.Int.toString(callCount1.contents) ++
        ", sub2=" ++
        Belt.Int.toString(callCount2.contents),
      )
    }

    unsub2()
  }

  {
    // Test 5: Error in one callback doesn't affect others

    let callCount1 = ref(0)
    let callCount2 = ref(0)

    let unsub1 = subscribe(_evt => {
      callCount1 := callCount1.contents + 1
      JsError.throwWithMessage("Intentional test error")
    })

    let unsub2 = subscribe(_evt => {
      callCount2 := callCount2.contents + 1
    })

    dispatch(NavCancelled)

    if callCount1.contents == 1 && callCount2.contents == 1 {
      Console.log("✓ Error in callback doesn't affect other subscribers")
    } else {
      Console.error(
        "✗ Error handling failed: sub1=" ++
        Belt.Int.toString(callCount1.contents) ++
        ", sub2=" ++
        Belt.Int.toString(callCount2.contents),
      )
    }

    unsub1()
    unsub2()
  }

  {
    // Test 6: Different event types are dispatched correctly

    let receivedEvents = ref([])

    let unsub = subscribe(evt => {
      receivedEvents := Belt.Array.concat(receivedEvents.contents, [evt])
    })

    dispatch(NavCancelled)
    dispatch(ClearSimUi)
    dispatch(LinkPreviewEnd)
    dispatch(CloseModal)

    if Belt.Array.length(receivedEvents.contents) == 4 {
      Console.log("✓ Different event types dispatched correctly")
    } else {
      Console.error(
        "✗ Event types failed: expected 4 events, got " ++
        Belt.Int.toString(Belt.Array.length(receivedEvents.contents)),
      )
    }

    unsub()
  }

  {
    // Test 7: NavProgress event with payload

    let receivedProgress = ref(None)

    let unsub = subscribe(evt => {
      switch evt {
      | NavProgress(progress) => receivedProgress := Some(progress)
      | _ => ()
      }
    })

    dispatch(NavProgress(0.75))

    switch receivedProgress.contents {
    | Some(0.75) => Console.log("✓ NavProgress event with payload")
    | Some(val) =>
      Console.error("✗ NavProgress failed: expected 0.75, got " ++ Belt.Float.toString(val))
    | None => Console.error("✗ NavProgress failed: no value received")
    }

    unsub()
  }

  {
    // Test 8: ShowNotification event with different severity levels

    let receivedNotifications = ref([])

    let unsub = subscribe(evt => {
      switch evt {
      | ShowNotification(msg, severity) =>
        receivedNotifications :=
          Belt.Array.concat(receivedNotifications.contents, [(msg, severity)])
      | _ => ()
      }
    })

    dispatch(ShowNotification("Info message", #Info))
    dispatch(ShowNotification("Success message", #Success))
    dispatch(ShowNotification("Error message", #Error))
    dispatch(ShowNotification("Warning message", #Warning))

    if Belt.Array.length(receivedNotifications.contents) == 4 {
      Console.log("✓ ShowNotification with different severity levels")
    } else {
      Console.error(
        "✗ ShowNotification failed: expected 4 notifications, got " ++
        Belt.Int.toString(Belt.Array.length(receivedNotifications.contents)),
      )
    }

    unsub()
  }

  {
    // Test 9: SceneArrived event with scene name

    let receivedSceneName = ref(None)

    let unsub = subscribe(evt => {
      switch evt {
      | SceneArrived(sceneName) => receivedSceneName := Some(sceneName)
      | _ => ()
      }
    })

    dispatch(SceneArrived("living-room"))

    switch receivedSceneName.contents {
    | Some("living-room") => Console.log("✓ SceneArrived event with scene name")
    | Some(name) =>
      Console.error("✗ SceneArrived failed: expected 'living-room', got '" ++ name ++ "'")
    | None => Console.error("✗ SceneArrived failed: no scene name received")
    }

    unsub()
  }

  {
    // Test 10: LinkPreviewStart event with URL

    let receivedUrl = ref(None)

    let unsub = subscribe(evt => {
      switch evt {
      | LinkPreviewStart(url) => receivedUrl := Some(url)
      | _ => ()
      }
    })

    dispatch(LinkPreviewStart("https://example.com/scene"))

    switch receivedUrl.contents {
    | Some("https://example.com/scene") => Console.log("✓ LinkPreviewStart event with URL")
    | Some(url) => Console.error("✗ LinkPreviewStart failed: unexpected URL '" ++ url ++ "'")
    | None => Console.error("✗ LinkPreviewStart failed: no URL received")
    }

    unsub()
  }

  {
    // Test 11: NavStart event with complex payload

    let receivedPayload = ref(None)

    let unsub = subscribe(evt => {
      switch evt {
      | NavStart(payload) => receivedPayload := Some(payload)
      | _ => ()
      }
    })

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
    | Some(payload) if payload.journeyId == 42 && payload.targetIndex == 5 =>
      Console.log("✓ NavStart event with complex payload")
    | Some(_) => Console.error("✗ NavStart failed: payload mismatch")
    | None => Console.error("✗ NavStart failed: no payload received")
    }

    unsub()
  }

  {
    // Test 12: ShowModal event with modal config

    let receivedModalConfig = ref(None)

    let unsub = subscribe(evt => {
      switch evt {
      | ShowModal(config) => receivedModalConfig := Some(config)
      | _ => ()
      }
    })

    let testModalConfig: modalConfig = {
      title: "Test Modal",
      description: Some("This is a test"),
      contentHtml: None,
      buttons: [],
      icon: Some("info"),
      allowClose: Some(true),
      onClose: None,
      className: None,
    }
    dispatch(ShowModal(testModalConfig))

    switch receivedModalConfig.contents {
    | Some(config) if config.title == "Test Modal" =>
      Console.log("✓ ShowModal event with modal config")
    | Some(_) => Console.error("✗ ShowModal failed: config mismatch")
    | None => Console.error("✗ ShowModal failed: no config received")
    }

    unsub()
  }

  {
    // Test 13: No subscribers doesn't cause errors

    // Dispatch events with no subscribers - should not throw
    dispatch(NavCancelled)
    dispatch(ClearSimUi)
    dispatch(NavProgress(0.5))

    Console.log("✓ Dispatching with no subscribers doesn't cause errors")
  }

  {
    // Test 14: Resubscribe after unsubscribe

    let callCount = ref(0)

    let unsub1 = subscribe(_evt => callCount := callCount.contents + 1)
    dispatch(NavCancelled)
    unsub1()

    let unsub2 = subscribe(_evt => callCount := callCount.contents + 1)
    dispatch(NavCancelled)

    if callCount.contents == 2 {
      Console.log("✓ Resubscribe after unsubscribe works")
    } else {
      Console.error(
        "✗ Resubscribe failed: expected 2 calls, got " ++ Belt.Int.toString(callCount.contents),
      )
    }

    unsub2()
  }

  Console.log("✓ EventBus: Module logic verified")
}
