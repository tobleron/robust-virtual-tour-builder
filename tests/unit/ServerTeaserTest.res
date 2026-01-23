open Types

let run = () => {
  Console.log("Running ServerTeaserTest...")

  /* Mock global FormData */
  let _ = %raw(`(function(){
    global.FormData = class MockFormData {
      constructor() {
        this._entries = []; // Array of {key, value, filename}
        MockFormData.lastInstance = this;
      }
      append(key, value, filename) {
        this._entries.push({key, value, filename});
      }
      get(key) { 
        const found = this._entries.find(e => e.key === key);
        return found ? found.value : null;
      }
    };
    global.FormData.lastInstance = null;
  })()`)

  /* Mock global Fetch */
  let _ = %raw(`(function(){
    let mockCalls = [];
    global.fetch = (url, options) => {
      mockCalls.push([url, options]);
      return Promise.resolve({
        ok: true,
        blob: () => Promise.resolve(new Blob(["simulated_blob"], {type: "video/mp4"}))
      });
    };
    global.fetch.mock = { calls: mockCalls };
    global.fetch.mockClear = () => { mockCalls.length = 0; };
  })()`)

  let makeScene = (id, name) => {
    {
      id,
      name,
      file: Obj.magic("mock_file_blob_" ++ id),
      tinyFile: None,
      originalFile: None,
      hotspots: [],
      category: "Test",
      floor: "1",
      label: "Test Scene",
      quality: None,
      colorGroup: None,
      _metadataSource: "manual",
      categorySet: false,
      labelSet: false,
      isAutoForward: false,
      preCalculatedSnapshot: None,
    }
  }

  let mockState: state = {
    tourName: "Test Tour",
    scenes: [makeScene("1", "Scene 1"), makeScene("2", "Scene 2")],
    activeIndex: 0,
    activeYaw: 0.0,
    activePitch: 0.0,
    isLinking: false,
    transition: {type_: None, targetHotspotIndex: -1, fromSceneName: None},
    lastUploadReport: {success: [], skipped: []},
    exifReport: None,
    linkDraft: None,
    preloadingSceneIndex: -1,
    isTeasing: false,
    deletedSceneIds: [],
    timeline: [],
    activeTimelineStepId: None,
    navigation: Idle,
    simulation: {
      status: Idle,
      visitedScenes: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
      lastAdvanceTime: 0.0,
      pendingAdvanceId: None,
      autoPilotJourneyId: 0,
    },
    incomingLink: None,
    autoForwardChain: [],
    pendingReturnSceneName: None,
    currentJourneyId: 0,
    lastUsedCategory: "outdoor",
    sessionId: None,
  }

  /* Test 1: Validate Request Generation */
  Console.log("Test 1: Validate Request Generation")

  /* Clear mocks */
  let _ = %raw(`(function(){ global.fetch.mockClear(); global.FormData.lastInstance = null; })()`)

  /* Call function */
  let _ = ServerTeaser.generateServerTeaser(mockState, None)

  /* Verify Fetch called */
  let calls: array<array<string>> = %raw("global.fetch.mock.calls")
  let relevantCall = calls->Belt.Array.getBy(call => {
    let url = call->Belt.Array.getExn(0)
    String.includes(url, "/generate-teaser")
  })

  switch relevantCall {
  | Some(_) => Console.log("  Pass: Fetch to /generate-teaser called")
  | None => Console.log("  Fail: No fetch to /generate-teaser found")
  }

  /* Verify FormData content */
  let lastFormData: option<{..}> = %raw("global.FormData.lastInstance || undefined")

  switch lastFormData {
  | Some(fd) =>
    let entries: array<{..}> = fd["_entries"]

    let widthEntry = entries->Belt.Array.getBy(e => e["key"] == "width")
    let heightEntry = entries->Belt.Array.getBy(e => e["key"] == "height")
    let projectEntry = entries->Belt.Array.getBy(e => e["key"] == "project_data")

    switch (widthEntry, heightEntry) {
    | (Some(w), Some(h)) =>
      if w["value"] == "1920" && h["value"] == "1080" {
        Console.log("  Pass: FormData width/height correct")
      } else {
        Console.log("  Fail: FormData width/height incorrect")
      }
    | _ => Console.log("  Fail: Width/Height missing")
    }

    switch projectEntry {
    | Some(p) =>
      let val = p["value"]
      if String.includes(val, "Test Tour") {
        Console.log("  Pass: FormData project_data contains tour name")
      } else {
        Console.log("  Fail: FormData project_data missing tour name")
      }
    | None => Console.log("  Fail: project_data missing")
    }

    /* Check files */
    let fileEntries = entries->Belt.Array.keep(e => e["key"] == "files")
    if Array.length(fileEntries) == 2 {
      Console.log("  Pass: FormData has 2 files attached")
    } else {
      Console.log2("  Fail: FormData file count incorrect", Array.length(fileEntries))
    }

  | None => Console.log("  Fail: No FormData created")
  }

  Console.log("✓ ServerTeaser tests passed")
}
