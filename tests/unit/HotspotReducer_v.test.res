/* tests/unit/HotspotReducer.test.res */
open Vitest
open Actions
open Types
open TestUtils

test("HotspotReducer: AddHotspot appends hotspot to specific scene", t => {
  let s1 = createMockScene(~id="s1", ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ~appMode=InteractiveAuthoring(Idle), ())
  let hotspot = createMockHotspot(~id="h1", ())

  let action = AddHotspot(0, hotspot)
  let result = Reducer.reducer(state, action)

  let scene = result.scenes[0]->Option.getOrThrow
  let hs = Belt.Array.get(scene.hotspots, 0)->Option.getOrThrow
  t->expect(hs.linkId)->Expect.toBe("h1")
})

test("HotspotReducer: RemoveHotspot removes hotspot via ReducerHelpers", t => {
  let h1 = createMockHotspot(~id="h1", ~target="s2", ())
  let s1 = createMockScene(~id="s1", ~name="s1", ~hotspots=[h1], ())
  let s2 = createMockScene(~id="s2", ~name="s2", ())
  let state = createMockState(
    ~scenes=[s1, s2],
    ~activeIndex=0,
    ~appMode=InteractiveAuthoring(Idle),
    (),
  )

  let action = RemoveHotspot(0, 0)
  let result = Reducer.reducer(state, action)

  let scene = result.scenes[0]->Option.getOrThrow
  t->expect(scene.hotspots->Array.length)->Expect.toBe(0)
})

test("HotspotReducer: ClearHotspots empties hotspots array for scene", t => {
  let h1 = createMockHotspot(~id="h1", ())
  let h2 = createMockHotspot(~id="h2", ())
  let s1 = createMockScene(~id="s1", ~hotspots=[h1, h2], ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ~appMode=InteractiveAuthoring(Idle), ())

  let action = ClearHotspots(0)
  let result = Reducer.reducer(state, action)

  let scene = result.scenes[0]->Option.getOrThrow
  t->expect(scene.hotspots->Array.length)->Expect.toBe(0)
})

test("HotspotReducer: UpdateHotspotTargetView updates view parameters", t => {
  let h1 = createMockHotspot(~id="h1", ())
  let s1 = createMockScene(~id="s1", ~hotspots=[h1], ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ~appMode=InteractiveAuthoring(Idle), ())

  let action = UpdateHotspotTargetView(0, 0, 120.0, -20.0, 60.0)
  let result = Reducer.reducer(state, action)

  let scene = result.scenes[0]->Option.getOrThrow
  let hs = Belt.Array.get(scene.hotspots, 0)->Option.getOrThrow
  t->expect(hs.targetYaw)->Expect.toEqual(Some(120.0))
  t->expect(hs.targetPitch)->Expect.toEqual(Some(-20.0))
  t->expect(hs.targetHfov)->Expect.toEqual(Some(60.0))
})

test("HotspotReducer: UpdateHotspotReturnView sets return frame and flag", t => {
  let h1 = createMockHotspot(~id="h1", ())
  let s1 = createMockScene(~id="s1", ~hotspots=[h1], ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ~appMode=InteractiveAuthoring(Idle), ())

  let action = UpdateHotspotReturnView(0, 0, 45.0, 10.0, 90.0)
  let result = Reducer.reducer(state, action)

  let scene = result.scenes[0]->Option.getOrThrow
  let hs = Belt.Array.get(scene.hotspots, 0)->Option.getOrThrow
  t->expect(hs.isReturnLink)->Expect.toEqual(Some(true))
  let rvf = hs.returnViewFrame->Option.getOrThrow
  t->expect(rvf.yaw)->Expect.toBe(45.0)
  t->expect(rvf.pitch)->Expect.toBe(10.0)
})

test("HotspotReducer: ToggleHotspotReturnLink toggles flag and initializes frame", t => {
  let h1 = createMockHotspot(~id="h1", ())
  let s1 = createMockScene(~id="s1", ~hotspots=[h1], ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ~appMode=InteractiveAuthoring(Idle), ())

  // First toggle: true
  let action = ToggleHotspotReturnLink(0, 0)
  let newState1 = Reducer.reducer(state, action)

  let scene1 = newState1.scenes[0]->Option.getOrThrow
  let hs1 = Belt.Array.get(scene1.hotspots, 0)->Option.getOrThrow
  t->expect(hs1.isReturnLink)->Expect.toEqual(Some(true))
  t->expect(hs1.returnViewFrame != None)->Expect.toBe(true)

  // Second toggle: false
  let newState2 = Reducer.reducer(newState1, action)
  let scene2 = newState2.scenes[0]->Option.getOrThrow
  let hs2 = Belt.Array.get(scene2.hotspots, 0)->Option.getOrThrow
  t->expect(hs2.isReturnLink)->Expect.toEqual(Some(false))
})

test("HotspotReducer: ignores actions with invalid indices", t => {
  let s1 = createMockScene(~id="s1", ())
  let state = createMockState(~scenes=[s1], ~activeIndex=0, ())

  let action = UpdateHotspotTargetView(5, 0, 0.0, 0.0, 0.0)
  let result = Reducer.reducer(state, action)

  t->expect(result.scenes->Array.length)->Expect.toBe(1)
})
