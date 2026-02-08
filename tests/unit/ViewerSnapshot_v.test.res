open Vitest

describe("ViewerSnapshot", () => {
  let _ = %raw(`
    (function() {
      if (!global.originalSetTimeout) {
        global.originalSetTimeout = window.setTimeout;
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
    let _ = %raw(`
      (function() {
        if (global.originalRevokeObjectURL) {
          window.URL.revokeObjectURL = global.originalRevokeObjectURL;
        }
      })()
    `)
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
    GlobalStateBridge.setState(mockState)

    // Mock Viewer
    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    // Trigger
    ViewerSnapshot.requestIdleSnapshot()

    // Trigger the captured callback manually
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(50)

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
    GlobalStateBridge.setState(mockState)

    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    SceneCache.clearAll()
    SceneCache.setSnapshot("s1", "blob:old-url")
    ViewerSnapshot.requestIdleSnapshot()
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(50)

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
    ViewerSnapshot.requestIdleSnapshot()
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
    ViewerSnapshot.requestIdleSnapshot()
    let _ = %raw(`global.capturedCallback && global.capturedCallback()`)

    await wait(20)
    t->expect(SceneCache.getSnapshot("s1"))->Expect.toBe(None)

    restore()
  })

  testAsync("should notify user when rate limited", async t => {
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
      })()
    `)

    // Setup NotificationManager Listener
    let notificationReceived = ref(false)
    let unsubscribe = NotificationManager.subscribe(
      queueState => {
        Belt.Array.forEach(
          queueState.pending,
          notif => {
            if notif.message->String.includes("Please wait") {
              notificationReceived := true
            }
          },
        )
        Belt.Array.forEach(
          queueState.active,
          notif => {
            if notif.message->String.includes("Please wait") {
              notificationReceived := true
            }
          },
        )
      },
    )

    // Setup Viewer
    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    // Call 12 times to hit rate limit (limit is 10)
    for _ in 1 to 12 {
      ViewerSnapshot.requestIdleSnapshot()
      let _ = %raw(`global.capturedCallback && global.capturedCallback()`)
    }

    await wait(50)

    t->expect(notificationReceived.contents)->Expect.toBe(true)

    unsubscribe()
    restore()
  })
})
