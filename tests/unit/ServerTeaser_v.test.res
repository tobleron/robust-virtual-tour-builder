// @efficiency: infra-adapter
/* tests/unit/ServerTeaser_v.test.res */
open Vitest
open Teaser.Server
open Types

// Global mocks
%%raw(`
  globalThis.fetch = vi.fn().mockResolvedValue({
    ok: true,
    blob: () => Promise.resolve(new Blob(["teaser"], { type: 'video/mp4' })),
    status: 200
  });

`)

describe("ServerTeaser - Remote Rendering", () => {
  beforeEach(() => {
    let _ = %raw(`vi.clearAllMocks()`)
  })

  let makeScene = (id, name): scene => {
    {
      id,
      name,
      file: Blob(%raw(`new globalThis.Blob(["data"], { type: "image/jpeg" })`)),
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
    }
  }

  let mockState: state = {
    tourName: "Test Tour",
    scenes: [makeScene("1", "Scene 1"), makeScene("2", "Scene 2")],
    inventory: Belt.Map.String.empty,
    sceneOrder: [],
    activeIndex: 0,
    activeYaw: 0.0,
    activePitch: 0.0,
    appMode: Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}),
    isLinking: false,
    transition: {type_: Fade, targetHotspotIndex: -1, fromSceneName: None},
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
    lastUsedCategory: "outdoor",
    sessionId: None,
    logo: None,
    structuralRevision: 0,
  }

  testAsync("generateServerTeaser sends correct FormData to backend", async t => {
    let result = await generateServerTeaser(mockState, None)

    switch result {
    | Ok(_) => t->expect(true)->Expect.toBe(true)
    | Error(msg) => t->expect(msg)->Expect.toBe("Success")
    }

    let fetchCalls = %raw(`globalThis.fetch.mock.calls`)
    t->expect(Array.length(fetchCalls))->Expect.toBe(1)

    let options = %raw(`globalThis.fetch.mock.calls[0][1]`)
    let body = options["body"]

    let getFromForm = (_fd, _key): string => %raw(`_fd.get(_key)`)
    let getAllFromForm = (_fd, _key): array<'a> => %raw(`_fd.getAll(_key)`)

    // Check width/height in FormData
    t->expect(getFromForm(body, "width"))->Expect.toBe("1920")
    t->expect(getFromForm(body, "height"))->Expect.toBe("1080")

    // Check that files were appended
    let files = getAllFromForm(body, "files")
    t->expect(Array.length(files))->Expect.toBe(2)
  })

  testAsync("generateServerTeaser handles server error", async t => {
    let _ = %raw(`
      globalThis.fetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: "Server Error",
        json: () => Promise.resolve({ error: "Internal Server Error" })
      })
    `)

    let result = await generateServerTeaser(mockState, None)

    switch result {
    | Ok(_) => t->expect("Success")->Expect.toBe("Error expected")
    | Error(msg) => t->expect(String.includes(msg, "Server Error"))->Expect.toBe(true)
    }
  })

  testAsync("generateServerTeaser handles network failure", async t => {
    let _ = %raw(`
      globalThis.fetch.mockRejectedValueOnce(new Error("Network Failure"))
    `)

    let result = await generateServerTeaser(mockState, None)

    switch result {
    | Ok(_) => t->expect("Success")->Expect.toBe("Error expected")
    | Error(msg) => t->expect(msg)->Expect.toBe("Unknown JS Error")
    }
  })

  testAsync("generateServerTeaser handles progress callbacks", async t => {
    let callbackCount = ref(0)
    let lastMsg = ref("")
    let onProgress = (pct, msg) => {
      let _ = pct
      lastMsg := msg
      callbackCount := callbackCount.contents + 1
    }

    let _ = await generateServerTeaser(mockState, Some(onProgress))

    t->expect(callbackCount.contents)->Expect.Int.toBeGreaterThanOrEqual(3)
    t->expect(lastMsg.contents)->Expect.toBe("Done!")
  })
})
