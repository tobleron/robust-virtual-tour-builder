open Vitest

describe("StateDensityMonitor", _ => {
  test("classifies score bands", t => {
    t->expect(StateDensityMonitor.classifyScore(0.0))->Expect.toBe(StateDensityMonitor.Healthy)
    t->expect(StateDensityMonitor.classifyScore(120.0))->Expect.toBe(StateDensityMonitor.Watch)
    t->expect(StateDensityMonitor.classifyScore(219.99))->Expect.toBe(StateDensityMonitor.Watch)
    t->expect(StateDensityMonitor.classifyScore(220.0))->Expect.toBe(StateDensityMonitor.High)
  })

  test("builds snapshot from initial state", t => {
    let snapshot = StateDensityMonitor.toSnapshot(State.initialState)
    t->expect(snapshot.sceneCount)->Expect.toBe(0)
    t->expect(snapshot.hotspotCount)->Expect.toBe(0)
    t->expect(snapshot.timelineCount)->Expect.toBe(0)
    t->expect(snapshot.deletedSceneCount)->Expect.toBe(0)
    t->expect(snapshot.level)->Expect.toBe(StateDensityMonitor.Healthy)
  })
})
