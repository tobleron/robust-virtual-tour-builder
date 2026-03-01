open Vitest

describe("ViewerSnapshot", () => {
  let _ = %raw(`
    (function() {
      if (!global.originalSetTimeout) {
        global.originalSetTimeout = window.setTimeout;
      }
      if (!global.originalDateNow) {
        global.originalDateNow = Date.now;
      }
      if (window.URL && !global.originalRevokeObjectURL) {
        global.originalRevokeObjectURL = window.URL.revokeObjectURL;
      }
    })()
  `)

  let setTimeoutRaw: (unit => unit, int) => unit = %raw(`
    function(cb, ms) {
      global.originalSetTimeout(cb, ms);
    }
  `)

  let wait = ms =>
    Promise.make((resolve, _) => {
      setTimeoutRaw(resolve, ms)
    })

  let restore = () => {
    let _ = %raw(`window.setTimeout = global.originalSetTimeout`)
    let _ = %raw(`Date.now = global.originalDateNow`)
    let _ = %raw(`
      (function() {
        if (global.originalRevokeObjectURL) {
          window.URL.revokeObjectURL = global.originalRevokeObjectURL;
        }
      })()
    `)
    SceneCache.clearAll()
    InteractionGuard.clear()
    NotificationManager.clear()
  }

  testAsync("snapshot logic should update scene state", async t => {
    // Setup Mock DOM and Timer
    let _ = %raw(`
      (function(){
        document.body.innerHTML = '<div id="panorama-a"><canvas></canvas></div>';
        // Mock toBlob
        HTMLCanvasElement.prototype.toBlob = function(cb, type, q) {
          cb(new Blob(['abc'], {type: 'image/webp'}));
        };
        
        // Mock Timers to trigger immediately
        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 999;
          }
          return global.originalSetTimeout(cb, delay);
        };
      })()
    `)

    // Setup State
    let scene = TestUtils.createMockScene(~id="s1", ~name="Scene 1", ())
    let mockState = TestUtils.createMockState(~scenes=[scene], ~activeIndex=0, ())
    AppStateBridge.updateState(mockState)

    // Mock Viewer
    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    // Trigger
    ViewerSnapshot.requestIdleSnapshot(~getState=AppStateBridge.getState)

    // Trigger the captured callback manually
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(100)

    t->expect(Belt.Option.isSome(SceneCache.getSnapshot("s1")))->Expect.toBe(true)

    restore()
  })

  testAsync("should revoke old object URL when capturing new snapshot", async t => {
    // Setup Mock DOM and Timer
    let _ = %raw(`
      (function(){
        document.body.innerHTML = '<div id="panorama-a"><canvas></canvas></div>';
        HTMLCanvasElement.prototype.toBlob = function(cb, type, q) {
          cb(new Blob(['new'], {type: 'image/webp'}));
        };
        
        global.revokedUrl = null;
        window.URL.revokeObjectURL = (url) => {
          global.revokedUrl = url;
        };

        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 998;
          }
          return global.originalSetTimeout(cb, delay);
        };
      })()
    `)

    let scene = TestUtils.createMockScene(~id="s1", ~name="Scene 1", ())
    let mockState = TestUtils.createMockState(~scenes=[scene], ~activeIndex=0, ())
    AppStateBridge.updateState(mockState)

    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    SceneCache.clearAll()
    SceneCache.setSnapshot("s1", "blob:old-url")
    ViewerSnapshot.requestIdleSnapshot(~getState=AppStateBridge.getState)
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(100)
    let revoked = %raw(`global.revokedUrl`)
    t->expect(revoked)->Expect.toBe("blob:old-url")

    restore()
  })

  testAsync("should skip capture if no viewer is active", async t => {
    let _ = %raw(`
      (function(){
        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 997;
          }
          return global.originalSetTimeout(cb, delay);
        };
      })()
    `)

    ViewerSystem.Pool.clearInstance("panorama-a")
    ViewerSystem.Pool.clearInstance("panorama-b")

    SceneCache.clearAll()
    ViewerSnapshot.requestIdleSnapshot(~getState=AppStateBridge.getState)
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(20)
    t->expect(SceneCache.getSnapshot("any"))->Expect.toBe(None)

    restore()
  })

  testAsync("should skip capture if no canvas is found", async t => {
    let _ = %raw(`
      (function(){
        document.body.innerHTML = '<div id="panorama-a"></div>'; // No canvas

        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 999;
          }
          return global.originalSetTimeout(cb, delay);
        };
      })()
    `)

    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    SceneCache.clearAll()
    ViewerSnapshot.requestIdleSnapshot(~getState=AppStateBridge.getState)
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(20)
    t->expect(SceneCache.getSnapshot("s1"))->Expect.toBe(None)

    restore()
  })

  testAsync("should not notify user for min-interval throttling", async t => {
    // Setup Mock DOM and Timer
    let _ = %raw(`
      (function(){
        document.body.innerHTML = '<div id="panorama-a"><canvas></canvas></div>';
        HTMLCanvasElement.prototype.toBlob = function(cb, type, q) {
          cb(new Blob(['abc'], {type: 'image/webp'}));
        };

        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 999;
          }
          return global.originalSetTimeout(cb, delay);
        };
        global.mockNow = 100000;
        Date.now = () => global.mockNow;
      })()
    `)

    // Setup NotificationManager Listener
    let notificationReceived = ref(false)
    let unsubscribe = NotificationManager.subscribe(
      queueState => {
        Belt.Array.forEach(
          queueState.pending,
          notif => {
            if notif.message->String.includes("Rendering") {
              notificationReceived := true
            }
          },
        )
        Belt.Array.forEach(
          queueState.active,
          notif => {
            if notif.message->String.includes("Rendering") {
              notificationReceived := true
            }
          },
        )
      },
    )

    // Setup Viewer
    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    // First call succeeds, second call is min-interval throttled (same Date.now)
    let _ = %raw(`ViewerSnapshot.debouncedSnapshot.call()`)
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)
    let _ = %raw(`ViewerSnapshot.debouncedSnapshot.call()`)
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(50)

    t->expect(notificationReceived.contents)->Expect.toBe(false)

    unsubscribe()
    restore()
  })

  testAsync("should notify once when quota rate limited within cooldown window", async t => {
    // Setup Mock DOM and Timer
    let _ = %raw(`
      (function(){
        document.body.innerHTML = '<div id="panorama-a"><canvas></canvas></div>';
        HTMLCanvasElement.prototype.toBlob = function(cb, type, q) {
          cb(new Blob(['abc'], {type: 'image/webp'}));
        };

        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 999;
          }
          return global.originalSetTimeout(cb, delay);
        };
        global.mockNow = 100000;
        Date.now = () => global.mockNow;
      })()
    `)

    let notificationEventCount = ref(0)
    let unsubscribe = NotificationManager.subscribe(
      queueState => {
        let hasRenderingInPending = Belt.Array.some(
          queueState.pending,
          notif => notif.message->String.includes("Rendering"),
        )
        let hasRenderingInActive = Belt.Array.some(
          queueState.active,
          notif => notif.message->String.includes("Rendering"),
        )
        if hasRenderingInPending || hasRenderingInActive {
          notificationEventCount := notificationEventCount.contents + 1
        }
      },
    )

    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    // Advance time by > minInterval so accepted calls consume quota quickly in one window.
    // After quota is exhausted, additional attempts stay within toast cooldown window.
    for _ in 1 to 22 {
      let _ = %raw(`global.mockNow += 1300`)
      let _ = %raw(`ViewerSnapshot.debouncedSnapshot.call()`)
      let _ = %raw(`global.capturedCallback && global.capturedCallback()`)
    }

    await wait(50)

    t->expect(notificationEventCount.contents)->Expect.toBe(1)

    unsubscribe()
    restore()
  })
})
