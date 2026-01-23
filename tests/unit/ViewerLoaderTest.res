/* tests/unit/ViewerLoaderTest.res */
open ViewerLoader

// Mock for Pannellum and Dom
%%raw(`
  globalThis.pannellum = {
    viewer: (id, config) => ({
      _id: id,
      _config: config,
      destroy: () => {},
      on: (event, cb) => {},
      getScene: () => "master",
      getPitch: () => 0.0,
      getYaw: () => 0.0,
      getHfov: () => 90.0,
      mouseEventToCoords: () => [0, 0]
    })
  };

  const createMockNode = (id) => ({
    id: id,
    classList: {
      add: () => {},
      remove: () => {},
      contains: () => false,
      toggle: () => {}
    },
    style: {},
    setAttribute: () => {},
    appendChild: () => {},
    remove: () => {},
    getBoundingClientRect: () => ({ top: 0, left: 0, width: 1000, height: 500 })
  });

  globalThis.document.getElementById = (id) => {
    if (id === "missing") return null;
    return createMockNode(id);
  };

  globalThis.getComputedStyle = () => ({
    opacity: "1",
    getPropertyValue: (p) => p === "opacity" ? "1" : ""
  });
`)

let run = () => {
  Console.log("Running ViewerLoader tests...")
  GlobalStateBridge.setState(State.initialState)

  // Test: getPanoramaUrl
  let url1 = getPanoramaUrl(Url("test.webp"))
  assert(url1 == "test.webp")
  let mockBlob = %raw(`({ size: 100, type: "image/webp" })`)
  let url2 = getPanoramaUrl(Blob(Obj.magic(mockBlob)))
  assert(url2->String.startsWith("blob:mock"))
  Console.log("✓ getPanoramaUrl")

  // Test: Loader.initializeViewer
  let viewer = Loader.initializeViewer("v1", %raw("{}"))
  assert(Obj.magic(viewer)["_id"] == "v1")
  Console.log("✓ initializeViewer")

  // Test: Loader.destroyViewer
  Loader.destroyViewer(viewer)
  Console.log("✓ destroyViewer")

  // Test: getComputedOpacity
  let opacity = getComputedOpacity(Obj.magic(%raw("createMockNode('test')")))
  assert(opacity == 1.0)
  Console.log("✓ getComputedOpacity")

  Console.log("ViewerLoader tests passed!")
}
