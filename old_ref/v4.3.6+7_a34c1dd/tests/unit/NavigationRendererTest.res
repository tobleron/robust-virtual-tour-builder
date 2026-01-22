/* tests/unit/NavigationRendererTest.res */
open NavigationRenderer
open Types
// open EventBus removed to avoid shadowing

let run = () => {
  Console.log("Running NavigationRenderer tests...")

  /* --- Mock Setup --- */
  let _ = %raw(`
    (function() {
        // Mock Window and RAF
        global.window = global.window || {};
        global.document = global.document || {};
        
        // RAF Mock
        global.pendingFrame = null;
        
        // Mock global RAF for ReBindings
        // Use globalThis to ensure visibility
        globalThis.requestAnimationFrame = (cb) => {
            global.pendingFrame = cb;
            return 1;
        };
        globalThis.cancelAnimationFrame = (id) => {
            global.pendingFrame = null;
        };
        
        // Alias to window just in case
        global.window.requestAnimationFrame = globalThis.requestAnimationFrame;
        global.window.cancelAnimationFrame = globalThis.cancelAnimationFrame;
        
        // Mock Date.now to allow time manipulation
        global.currentTime = 100000.0;
        global.originalDateNow = Date.now;
        Date.now = () => global.currentTime;

        // Mock Helper for creating elements
        let createMockElement = () => ({
             innerHTML: "",
             style: {
                 setProperty: () => {},
                 removeProperty: () => {}
             },
             appendChild: () => {},
             removeChild: () => {},
             setAttribute: () => {},
             getBoundingClientRect: () => ({
                 width: 1000.0, height: 800.0, top: 0.0, left: 0.0,
                 right: 1000.0, bottom: 800.0, x: 0.0, y: 0.0
             }),
             addEventListener: () => {},
             removeEventListener: () => {}
        });

        // Mock Document
        global.document.getElementById = (id) => createMockElement();
        global.document.createElementNS = (ns, tag) => createMockElement();
        
        // Mock Viewer (ReBindings.viewer binds to window.pannellumViewer)
        global.window.pannellumViewer = {
            pitch: 0.0,
            yaw: 0.0,
            hfov: 100.0,
            setPitch: function(p, b) { this.pitch = p; },
            setYaw: function(y, b) { this.yaw = y; },
            setHfov: function(h, b) { this.hfov = h; },
            getPitch: function() { return this.pitch; },
            getYaw: function() { return this.yaw; },
            getHfov: function() { return this.hfov; },
            mouseEventToCoords: () => [0.0, 0.0]
        };

        // Mock Helpers for Test Control
        global.tick = (ms) => {
            global.currentTime += ms;
            if (global.pendingFrame) {
                let cb = global.pendingFrame;
                global.pendingFrame = null;
                cb();
            }
        };
        
        global.resetTime = () => {
             global.currentTime = 100000.0;
             global.pendingFrame = null;
        };
    })()
  `)

  let tick: float => unit = %raw(`(ms) => global.tick(ms)`)
  let resetTime: unit => unit = %raw(`() => global.resetTime()`)
  let getViewerYaw: unit => float = %raw(`() => global.window.pannellumViewer.yaw`)
  let getViewerPitch: unit => float = %raw(`() => global.window.pannellumViewer.pitch`)

  /* Initialize the renderer (subscriptions) */
  init()

  /* Test 1: Start Journey Verification */
  let testStartJourney = () => {
    resetTime()
    Console.log("  Testing Start Journey...")

    let pathData: Types.pathData = {
      startPitch: 0.0,
      startYaw: 0.0,
      startHfov: 100.0,
      arrivalPitch: 10.0,
      arrivalYaw: 90.0,
      arrivalHfov: 90.0,
      panDuration: 1000.0,
      totalPathDistance: 100.0,
      targetPitchForPan: 10.0,
      targetYawForPan: 90.0,
      targetHfovForPan: 90.0,
      segments: [],
      waypoints: [],
    }

    let payload: EventBus.navStartPayload = {
      journeyId: 1,
      pathData,
      sourceIndex: 0,
      targetIndex: 1,
      hotspotIndex: 0,
      previewOnly: false,
    }

    /* Verify start position is set immediately */
    EventBus.dispatch(NavStart(payload))

    let yaw = getViewerYaw()
    let pitch = getViewerPitch()

    if yaw !== 0.0 || pitch !== 0.0 {
      Console.log("    FAILED: Start position not set correctly. Yaw: " ++ Float.toString(yaw))
    } else {
      Console.log("    Pass: Start position set")
    }

    /* Advance time to 500ms (50% progress) */
    tick(500.0)
  }

  /* Test 2: Interpolation */
  let testInterpolation = () => {
    resetTime()
    Console.log("  Testing Interpolation...")

    let segment: Types.pathSegment = {
      p1: {pitch: 0.0, yaw: 0.0},
      p2: {pitch: 10.0, yaw: 100.0},
      dist: 100.0,
      pitchDiff: 10.0,
      yawDiff: 100.0,
    }

    let pathData: Types.pathData = {
      startPitch: 0.0,
      startYaw: 0.0,
      startHfov: 100.0,
      arrivalPitch: 10.0,
      arrivalYaw: 100.0,
      arrivalHfov: 100.0,
      panDuration: 1000.0,
      totalPathDistance: 100.0,
      targetPitchForPan: 10.0,
      targetYawForPan: 100.0,
      targetHfovForPan: 100.0,
      segments: [segment],
      waypoints: [],
    }

    let payload: EventBus.navStartPayload = {
      journeyId: 2,
      pathData,
      sourceIndex: 0,
      targetIndex: 1,
      hotspotIndex: 0,
      previewOnly: false,
    }

    EventBus.dispatch(NavStart(payload))

    /* Adv 500ms -> 50% progress */
    tick(500.0)

    let yaw = getViewerYaw()
    if Math.abs(yaw -. 50.0) > 1.0 {
      Console.log(
        "    FAILED: Interpolation 50% incorrect. Expected ~50, got " ++ Float.toString(yaw),
      )
    } else {
      Console.log("    Pass: Interpolation 50% correct")
    }

    /* Adv another 500ms -> 100% progress -> Blink phase */
    tick(501.0)

    let yawEnd = getViewerYaw()
    if Math.abs(yawEnd -. 100.0) > 0.1 {
      Console.log(
        "    FAILED: End position incorrect. Expected 100, got " ++ Float.toString(yawEnd),
      )
    } else {
      Console.log("    Pass: End position reached")
    }
  }

  /* Test 3: Cancellation */
  let testCancellation = () => {
    Console.log("  Testing Cancellation...")
    EventBus.dispatch(NavCancelled)
    tick(100.0)
    Console.log("    Pass: Cancellation handled safely")
  }

  testStartJourney()
  testInterpolation()
  testCancellation()

  Console.log("✓ NavigationRenderer tests passed")
}
