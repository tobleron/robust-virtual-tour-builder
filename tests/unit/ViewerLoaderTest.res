/* tests/unit/ViewerLoaderTest.res */
open ViewerLoader
open ReBindings

// Mock for Pannellum
%%raw(`
  globalThis.pannellum = {
    viewer: (id, config) => {
      return {
        _id: id,
        _config: config,
        destroy: () => {},
        on: (event, cb) => {},
        getScene: () => "master",
        getPitch: () => 0.0,
        getYaw: () => 0.0,
        getHfov: () => 90.0,
        mouseEventToCoords: () => [0, 0]
      }
    }
  };
`)

// Mock for Dom and Browser APIs
%%raw(`
  globalThis.document = {
    getElementById: (id) => {
      if (id === "missing") return null;
      return { 
        id: id, 
        classList: { 
          add: () => {}, 
          remove: () => {}, 
          contains: () => false,
          toggle: () => {}
        }, 
        style: {},
        setAttribute: () => {},
        appendChild: () => {}
      };
    },
    createElement: (tag) => {
      const el = { 
        tagName: tag.toUpperCase(), 
        setAttribute: (k, v) => { el[k] = v; }, 
        addEventListener: (ev, cb) => {
          if (ev === 'load') setTimeout(cb, 0);
        },
        style: {}
      };
      return el;
    },
    body: { 
      appendChild: (el) => { 
        if (!globalThis.document._scripts) globalThis.document._scripts = [];
        globalThis.document._scripts.push(el); 
      } 
    },
    querySelectorAll: () => {
       return { length: 0 };
    }
  };
  globalThis.window = {
    setTimeout: (cb, ms) => setTimeout(cb, ms),
    clearTimeout: (id) => clearTimeout(id),
    getComputedStyle: () => ({ opacity: "1" }),
    pannellumViewer: null
  };
  globalThis.getComputedStyle = globalThis.window.getComputedStyle;
  globalThis.URL = {
    createObjectURL: () => "blob:mock",
    revokeObjectURL: () => {}
  };
  globalThis.Blob = class { constructor() {} };
  globalThis.File = class extends globalThis.Blob { constructor() { super(); } };
`)

let run = () => {
  Console.log("Running ViewerLoader tests...")

  // Test: getPanoramaUrl
  let url1 = getPanoramaUrl(Obj.magic("test.webp"))
  assert(url1 == "test.webp")

  let mockBlob = %raw(`new Blob()`)
  let url2 = getPanoramaUrl(Obj.magic(mockBlob))
  assert(url2 == "blob:mock")
  Console.log("✓ getPanoramaUrl")

  // Test: Loader.initializeViewer
  let mockContainer = "viewer-container"
  let mockConfig = {"default": {"firstScene": "master"}}
  let viewer = Loader.initializeViewer(mockContainer, Obj.magic(mockConfig))
  assert(Obj.magic(viewer)["_id"] == mockContainer)
  Console.log("✓ initializeViewer")

  // Test: Loader.destroyViewer
  // Should not throw
  Loader.destroyViewer(viewer)
  Console.log("✓ destroyViewer")

  // Test: getComputedOpacity
  let mockEl = %raw(`{}`)
  let opacity = getComputedOpacity(Obj.magic(mockEl))
  assert(opacity == 1.0)
  
  let opacityNull = getComputedOpacity(Obj.magic(Nullable.null))
  assert(opacityNull == 1.0)
  Console.log("✓ getComputedOpacity (including null)")

  // Test: Error handling for missing container
  // initializeViewer itself doesn't check container exists (Pannellum does internally in JS)
  // but we can verify that getElementById is called.
  
  // Test: invalid panorama URL logic in getPanoramaUrl
  let url3 = getPanoramaUrl(Obj.magic(123)) // Invalid type
  assert(url3 == "")
  Console.log("✓ getPanoramaUrl edge cases")

  Console.log("ViewerLoader tests passed!")
}
