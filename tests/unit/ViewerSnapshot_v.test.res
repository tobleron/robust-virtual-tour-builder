open Vitest
open ReBindings

describe("ViewerSnapshot", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

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
        const oldSetTimeout = window.setTimeout;
        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 999;
          }
          return oldSetTimeout(cb, delay);
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
    let _ = %raw(`global.capturedCallback()`)

    await wait(50)

    t->expect(Belt.Option.isSome(SceneCache.getSnapshot("s1")))->Expect.toBe(true)

    // Restore setTimeout
    let _ = %raw(`window.setTimeout = global.originalSetTimeout || window.setTimeout`)
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

        const oldSetTimeout = window.setTimeout;
        global.capturedCallback = null;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 998;
          }
          return oldSetTimeout(cb, delay);
        };
      })()
    `)

    let scene = TestUtils.createMockScene(~id="s1", ~name="Scene 1", ())
    let mockState = TestUtils.createMockState(~scenes=[scene], ~activeIndex=0, ())
    GlobalStateBridge.setState(mockState)

    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    SceneCache.setSnapshot("s1", "blob:old-url")
    ViewerSnapshot.requestIdleSnapshot()
    let _ = %raw(`global.capturedCallback()`)

    await wait(50)

    let revoked = %raw(`global.revokedUrl`)
    t->expect(revoked)->Expect.toBe("blob:old-url")

    // Restore
    let _ = %raw(`window.setTimeout = global.originalSetTimeout || window.setTimeout`)
  })

  testAsync("should skip capture if no viewer is active", async t => {
    let _ = %raw(`
      (function(){
        global.capturedCallback = null;
        const oldSetTimeout = window.setTimeout;
        window.setTimeout = (cb, delay) => {
          if (delay === 1000) {
            global.capturedCallback = cb;
            return 997;
          }
          return oldSetTimeout(cb, delay);
        };
      })()
    `)

    ViewerSystem.Pool.clearInstance("panorama-a")
    ViewerSystem.Pool.clearInstance("panorama-b")

    SceneCache.clearAll()
    ViewerSnapshot.requestIdleSnapshot()
    let _ = %raw(`global.capturedCallback()`)

    await wait(20)
    t->expect(SceneCache.getSnapshot("any"))->Expect.toBe(None)
  })

  testAsync("should skip capture if no canvas is found", async t => {
    let _ = %raw(`
      (function(){
        document.body.innerHTML = '<div id="panorama-a"></div>'; // No canvas
        global.capturedCallback = null;
      })()
    `)

    ViewerSystem.Pool.registerInstance("panorama-a", Obj.magic({"id": "mock_viewer"}))

    SceneCache.clearAll()
    ViewerSnapshot.requestIdleSnapshot()
    let _ = %raw(`global.capturedCallback()`)

    await wait(20)
    t->expect(SceneCache.getSnapshot("s1"))->Expect.toBe(None)
  })
})
