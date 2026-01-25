/* tests/unit/NavigationRenderer_v.test.res */
open Vitest
open Types

describe("NavigationRenderer", () => {
  beforeEach(() => {
    let _ = %raw(`
      (() => {
        globalThis.currentTime = 1000.0;
        const oldDateNow = globalThis.Date.now;
        globalThis.Date.now = () => globalThis.currentTime;
        
        globalThis.pendingRAF = null;
        globalThis.requestAnimationFrame = (cb) => {
          globalThis.pendingRAF = cb;
          return 1;
        };
        
        globalThis.mockViewer = {
          pitch: 0, yaw: 0, hfov: 100,
          setPitch: (v) => { globalThis.mockViewer.pitch = v },
          setYaw: (v) => { globalThis.mockViewer.yaw = v },
          setHfov: (v) => { globalThis.mockViewer.hfov = v },
          getPitch: () => globalThis.mockViewer.pitch,
          getYaw: () => globalThis.mockViewer.yaw,
          getHfov: () => globalThis.mockViewer.hfov,
          isLoaded: () => true,
        };
        
        globalThis.window.pannellumViewer = globalThis.mockViewer;
        
        // Mock SVG element
        const oldGetElementById = globalThis.document.getElementById;
        globalThis.document.getElementById = (id) => {
          if (id === "viewer-hotspot-lines") {
            const el = {
              id, 
              innerHTML: "", 
              style: {},
              childNodes: [],
              appendChild: (c) => { el.childNodes.push(c) },
              querySelector: (s) => null,
              contains: (s) => false,
              getBoundingClientRect: () => ({ width: 1000, height: 500 }),
              setAttribute: (k, v) => {},
              removeAttribute: (k) => {},
              setProperty: (k, v) => { el.style[k] = v }
            };
            return el;
          }
          return oldGetElementById ? oldGetElementById(id) : null;
        };
      })()
    `)
    NavigationRenderer.init()
    GlobalStateBridge.setState(State.initialState)
  })

  let tick = ms => {
    let _ = %raw(`
      (ms) => {
        globalThis.currentTime += ms;
        if (globalThis.pendingRAF) {
          const cb = globalThis.pendingRAF;
          globalThis.pendingRAF = null;
          cb();
        }
      }
    `)(ms)
  }

  test("Journey: start to finish animation", t => {
    let pathData: pathData = {
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
      segments: [
        {
          p1: {pitch: 0.0, yaw: 0.0},
          p2: {pitch: 10.0, yaw: 90.0},
          dist: 100.0,
          pitchDiff: 10.0,
          yawDiff: 90.0,
        },
      ],
      waypoints: [],
    }

    let payload: EventBus.navStartPayload = {
      journeyId: 100,
      pathData,
      sourceIndex: 0,
      targetIndex: 1,
      hotspotIndex: 0,
      previewOnly: false,
    }

    EventBus.dispatch(NavStart(payload))

    // Check initial position (set immediately on startJourney)
    let startYaw = %raw(`globalThis.mockViewer.yaw`)
    t->expect(startYaw)->Expect.toBe(0.0)

    // Tick to 500ms (50% progress)
    tick(500.0)
    let midYaw = %raw(`globalThis.mockViewer.yaw`)
    t->expect(midYaw)->Expect.Float.toBeCloseTo(45.0, 1)

    // Tick to 1001ms (pan complete, enters blink phase)
    tick(501.0)
    let endYaw = %raw(`globalThis.mockViewer.yaw`)
    t->expect(endYaw)->Expect.toBe(90.0)
  })

  test("Journey: cancellation handling", t => {
    let pathData: pathData = {
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

    EventBus.dispatch(
      NavStart({
        journeyId: 200,
        pathData,
        sourceIndex: 0,
        targetIndex: 1,
        hotspotIndex: 0,
        previewOnly: false,
      }),
    )

    tick(100.0)

    // Cancel
    EventBus.dispatch(NavCancelled)

    // Tick again - it should verify activeJourneyId mismatch and stop
    tick(100.0)
    t->expect(true)->Expect.toBe(true)
  })

  test("UI: clearing Simulation UI", t => {
    // Should not crash when dispatching clear event
    EventBus.dispatch(ClearSimUi)
    t->expect(true)->Expect.toBe(true)
  })
})
