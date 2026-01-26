open Vitest
open ReBindings
open Types

describe("ViewerSnapshot", () => {
  let wait = ms =>
    Promise.make((resolve, _) => {
      let _ = Window.setTimeout(() => resolve(), ms)
    })

  test("requestIdleSnapshot should set a timeout", t => {
    ViewerState.state.idleSnapshotTimeout = Nullable.null

    ViewerSnapshot.requestIdleSnapshot()

    t->expect(ViewerState.state.idleSnapshotTimeout)->Expect.not->Expect.toBe(Nullable.null)

    // Cleanup
    switch Nullable.toOption(ViewerState.state.idleSnapshotTimeout) {
    | Some(id) => Window.clearTimeout(id)
    | None => ()
    }
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
          if (delay === require('../../src/utils/Constants.bs.js').idleSnapshotDelay) {
            global.capturedCallback = cb;
            return 999;
          }
          return oldSetTimeout(cb, delay);
        };
      })()
    `)

    // Setup State
    let scene: scene = {
      id: "s1",
      name: "Scene 1",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "test",
      floor: "1",
      label: "label",
      quality: None,
      colorGroup: None,
      _metadataSource: "manual",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }

    let mockState = {
      ...State.initialState,
      scenes: [scene],
      activeIndex: 0,
    }
    GlobalStateBridge.setState(mockState)

    // Mock Viewer
    ViewerState.state.viewerA = Obj.magic({"id": "mock_viewer"})
    ViewerState.state.activeViewerKey = A

    // Trigger
    ViewerSnapshot.requestIdleSnapshot()

    // Trigger the captured callback manually
    let _ = %raw(`global.capturedCallback()`)

    await wait(50)

    switch Belt.Array.get(GlobalStateBridge.getState().scenes, 0) {
    | Some(s) => t->expect(Belt.Option.isSome(SceneCache.getSnapshot(s.id)))->Expect.toBe(true)
    | None => t->expect(false)->Expect.toBe(true)
    }

    // Restore setTimeout
    let _ = %raw(`window.setTimeout = require('node:timers').setTimeout`)
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
          if (delay === require('../../src/utils/Constants.bs.js').idleSnapshotDelay) {
            global.capturedCallback = cb;
            return 998;
          }
          return oldSetTimeout(cb, delay);
        };
      })()
    `)

    let scene: scene = {
      id: "s1",
      name: "Scene 1",
      file: Url(""),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "test",
      floor: "1",
      label: "label",
      quality: None,
      colorGroup: None,
      _metadataSource: "manual",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
    }

    let mockState = {
      ...State.initialState,
      scenes: [scene],
      activeIndex: 0,
    }
    GlobalStateBridge.setState(mockState)

    ViewerState.state.viewerA = Obj.magic({"id": "mock_viewer"})
    ViewerState.state.activeViewerKey = A

    SceneCache.setSnapshot("s1", "blob:old-url")
    ViewerSnapshot.requestIdleSnapshot()
    let _ = %raw(`global.capturedCallback()`)

    await wait(50)

    let revoked = %raw(`global.revokedUrl`)
    t->expect(revoked)->Expect.toBe("blob:old-url")

    // Restore
    let _ = %raw(`window.setTimeout = require('node:timers').setTimeout`)
    let _ = %raw(`window.URL.revokeObjectURL = () => {}`) // dummy restore
  })
})
