
open Vitest
open Capability

module MockTask = {
  let make = (
    id,
    type_,
    status,
    ~scope=OperationLifecycle.Ambient,
    ~phase="Running",
    (),
  ): OperationLifecycle.task => {
    {
      id,
      type_,
      scope,
      phase,
      cancellable: true,
      correlationId: None,
      status,
      startedAt: 0.0,
      updatedAt: 0.0,
      meta: None,
      visibleAfterMs: 0,
    }
  }
}

describe("Capability Policy Matrix", () => {
  test("All capabilities allowed when idle", t => {
    let ops = []
    t->expect(Policy.evaluate(CanNavigate, ops))->Expect.toBe(true)
    t->expect(Policy.evaluate(CanEditHotspots, ops))->Expect.toBe(true)
    t->expect(Policy.evaluate(CanUpload, ops))->Expect.toBe(true)
    t->expect(Policy.evaluate(CanExport, ops))->Expect.toBe(true)
    t->expect(Policy.evaluate(CanMutateProject, ops))->Expect.toBe(true)
    t->expect(Policy.evaluate(CanStartSimulation, ops))->Expect.toBe(true)
    t->expect(Policy.evaluate(CanInteractWithViewer, ops))->Expect.toBe(true)
  })

  test("Critical operations (ProjectLoad) block everything", t => {
    let ops = [
      MockTask.make("op1", OperationLifecycle.ProjectLoad, Active({progress: 0.0, message: None}), ()),
    ]

    t->expect(Policy.evaluate(CanNavigate, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanEditHotspots, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanUpload, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanExport, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanMutateProject, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanStartSimulation, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanInteractWithViewer, ops))->Expect.toBe(false)
  })

  test("Navigation blocks other navigation and hotspot editing", t => {
    let ops = [
      MockTask.make("op1", OperationLifecycle.Navigation, Active({progress: 0.0, message: None}), ()),
    ]

    t->expect(Policy.evaluate(CanNavigate, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanEditHotspots, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanInteractWithViewer, ops))->Expect.toBe(false)

    // Should still allow unrelated things?
    // Current policy blocks simulation start if navigation active
    t->expect(Policy.evaluate(CanStartSimulation, ops))->Expect.toBe(false)

    // Upload/Export/MutateProject might be allowed during simple nav?
    // Policy says:
    // CanUpload: !anyActive(Upload) -> true (Navigation doesn't block Upload)
    t->expect(Policy.evaluate(CanUpload, ops))->Expect.toBe(true)
  })

  test("ThumbnailGeneration (Ambient) blocks export/mutation but allows navigation", t => {
    let ops = [
      MockTask.make(
        "op1",
        OperationLifecycle.ThumbnailGeneration,
        Active({progress: 0.0, message: None}),
        ~scope=OperationLifecycle.Ambient,
        ()
      ),
    ]

    t->expect(Policy.evaluate(CanNavigate, ops))->Expect.toBe(true)
    t->expect(Policy.evaluate(CanInteractWithViewer, ops))->Expect.toBe(true)

    // Blocks mutation/export as data is being processed
    t->expect(Policy.evaluate(CanMutateProject, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanExport, ops))->Expect.toBe(false)
  })

  test("Simulation blocks most interactions", t => {
     let ops = [
      MockTask.make("op1", OperationLifecycle.Simulation, Active({progress: 0.0, message: None}), ()),
    ]

    t->expect(Policy.evaluate(CanNavigate, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanEditHotspots, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanStartSimulation, ops))->Expect.toBe(false)
    t->expect(Policy.evaluate(CanMutateProject, ops))->Expect.toBe(false)
  })
})
