/* tests/unit/TeaserPathfinderTest.res */
open TeaserPathfinder
open ReBindings

type mockObj = {
  "reset": unit => unit,
  "getCallCount": unit => int,
  "getLastPayload": unit => JSON.t,
  "restore": unit => unit,
}

let run = () => {
  Console.log("Running TeaserPathfinder tests...")

  // 1. Module and function existence
  let _ = getWalkPath
  let _ = getTimelinePath
  Console.log("✓ Functions getWalkPath and getTimelinePath exist")

  // 2. Test getWalkPath with global fetch mock
  // We'll use %raw to mock fetch which BackendApi uses
  let _ = %raw(`
    (() => {
    const originalFetch = globalThis.fetch;
    let callCount = 0;
    let lastPayload = null;
    let lastUrl = null;

    globalThis.fetch = (url, options) => {
      callCount++;
      lastUrl = url;
      lastPayload = options && options.body ? JSON.parse(options.body) : null;
      return Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve([])
      });
    };

    globalThis.mockFetch = {
      getCallCount: () => callCount,
      getLastPayload: () => lastPayload,
      getLastUrl: () => lastUrl,
      reset: () => { callCount = 0; lastPayload = null; lastUrl = null; },
      restore: () => { globalThis.fetch = originalFetch; }
    };
    })()
  `)

  let mock: mockObj = %raw(`globalThis.mockFetch`)

  // Test getWalkPath
  mock["reset"]()
  let _ = getWalkPath([], false)
  assert(mock["getCallCount"]() == 1)
  let p1 = mock["getLastPayload"]()
  let p1Dict = p1->JSON.Decode.object->Option.getExn
  assert(p1Dict->Dict.get("type")->Option.flatMap(JSON.Decode.string) == Some("walk"))
  assert(p1Dict->Dict.get("scenes")->Option.flatMap(JSON.Decode.array)->Option.map(Array.length) ==
    Some(0))
  assert(p1Dict->Dict.get("skipAutoForward")->Option.flatMap(JSON.Decode.bool) == Some(false))
  Console.log("✓ getWalkPath calls BackendApi.calculatePath with correct payload")

  // Test getTimelinePath
  mock["reset"]()
  let _ = getTimelinePath([], [], true)
  assert(mock["getCallCount"]() == 1)
  let p2 = mock["getLastPayload"]()
  let p2Dict = p2->JSON.Decode.object->Option.getExn
  assert(p2Dict->Dict.get("type")->Option.flatMap(JSON.Decode.string) == Some("timeline"))
  assert(p2Dict
  ->Dict.get("timeline")
  ->Option.flatMap(JSON.Decode.array)
  ->Option.map(Array.length) == Some(0))
  assert(p2Dict->Dict.get("scenes")->Option.flatMap(JSON.Decode.array)->Option.map(Array.length) ==
    Some(0))
  assert(p2Dict->Dict.get("skipAutoForward")->Option.flatMap(JSON.Decode.bool) == Some(true))
  Console.log("✓ getTimelinePath calls BackendApi.calculatePath with correct payload")

  mock["restore"]()

  Console.log("TeaserPathfinder tests passed!")
}
