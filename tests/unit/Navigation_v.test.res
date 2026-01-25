/* tests/unit/Navigation.test.res */
open Vitest
open Types
open NavigationGraph
open SceneSwitcher
open TestUtils

test("Navigation: findSceneByName locates scene", t => {
  let s1 = createMockScene(~id="1", ~name="s1.webp", ())
  let state = createMockState(~scenes=[s1], ())

  let found = findSceneByName(state.scenes, "s1.webp")
  t->expect(found->Option.map(s => s.id))->Expect.toEqual(Some("1"))

  let notFound = findSceneByName(state.scenes, "missing")
  t->expect(notFound)->Expect.toBe(None)
})

test("Navigation: getNextScene wraps around", t => {
  let scenes = [createMockScene(), createMockScene()]
  t->expect(getNextScene(scenes, 0))->Expect.toEqual(Some(1))
  t->expect(getNextScene(scenes, 1))->Expect.toEqual(Some(0))
})

test("Navigation: calculatePathData uses hotspot start params", t => {
  let hotspot = createMockHotspot()
  let hotspot = {
    ...hotspot,
    startYaw: Some(10.0),
    startPitch: Some(20.0),
    startHfov: Some(110.0),
  }
  let s1 = createMockScene(~id="s1", ~hotspots=[hotspot], ())
  let s2 = createMockScene(~id="s2", ())
  let state = createMockState(~scenes=[s1, s2], ())

  let pathData = calculatePathData(state, 0, 0, 1, 45.0, 15.0, 90.0, (0.0, 0.0, 90.0)) // sourceSceneIndex // sourceHotspotIndex // targetIndex // targets // currentView

  let pd = pathData->Option.getOrThrow
  t->expect(pd.startYaw)->Expect.toBe(10.0)
  t->expect(pd.startPitch)->Expect.toBe(20.0)
  t->expect(pd.startHfov)->Expect.toBe(90.0) // from currentView
  t->expect(pd.arrivalYaw)->Expect.toBe(45.0)
})

test("Navigation: calculateSmartArrivalTarget prioritizes forward links", t => {
  // Hotspot 0: return link
  let h0 = {
    ...createMockHotspot(~id="h0", ()),
    isReturnLink: Some(true),
    startYaw: Some(100.0),
    startPitch: Some(0.0),
  }
  // Hotspot 1: forward link
  let h1 = {
    ...createMockHotspot(~id="h1", ()),
    isReturnLink: Some(false),
    startYaw: Some(200.0),
    startPitch: Some(0.0),
  }

  let s1 = createMockScene(~id="s1", ~hotspots=[h0, h1], ())
  let scenes = [s1]

  let (y, _p, _h) = calculateSmartArrivalTarget(scenes, 0)
  t->expect(y)->Expect.toBe(200.0) // Should pick h1 because it's NOT a return link
})

test("Navigation: handleAutoForward detects loops", t => {
  let actions = []
  let dispatch = a => {
    let _ = Array.push(actions, a)
  }

  let s1 = createMockScene(~id="s1", ~name="s1", ~isAutoForward=true, ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ())
  let state = {...state, autoForwardChain: [0]} // Scene 0 already in chain

  handleAutoForward(dispatch, state, s1)

  // Should dispatch ResetAutoForwardChain
  let hasReset = actions->Array.some(a => a == Actions.ResetAutoForwardChain)
  t->expect(hasReset)->Expect.toBe(true)
})

test("Navigation: handleAutoForward jumps to target", t => {
  let actions = []
  let dispatch = a => {
    let _ = Array.push(actions, a)
  }

  // h1 targets s2
  let h1 = createMockHotspot(~id="h1", ~target="s2", ())
  let s1 = createMockScene(~id="s1", ~name="s1", ~hotspots=[h1], ~isAutoForward=true, ())
  let s2 = createMockScene(~id="s2", ~name="s2", ())
  let state = createMockState(~scenes=[s1, s2], ~activeIndex=0, ())

  handleAutoForward(dispatch, state, s1)

  // Should add s1 to chain
  let hasAddedToChain = actions->Array.some(a => {
    switch a {
    | AddToAutoForwardChain(0) => true
    | _ => false
    }
  })
  t->expect(hasAddedToChain)->Expect.toBe(true)
})
