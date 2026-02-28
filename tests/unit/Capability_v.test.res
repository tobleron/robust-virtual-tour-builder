open Vitest
open Types

module MockTask = {
  let make = (
    ~id: string,
    ~type_: OperationLifecycle.operationType,
    ~status: OperationLifecycle.status=Active({progress: 0.0, message: None}),
    ~scope: OperationLifecycle.scope=OperationLifecycle.Ambient,
    (),
  ): OperationLifecycle.task => {
    {
      id,
      type_,
      scope,
      phase: "Running",
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

let interactiveMode: appMode = Interactive({
  uiMode: Viewing,
  navigation: IdleFsm,
  backgroundTask: None,
})

let loadingMode: appMode = SystemBlocking(ProjectLoading({name: "Load", pendingAction: None}))

describe("Capability.Policy", () => {
  test("allows all capabilities when interactive and idle", t => {
    let ops = []

    t
    ->expect(Capability.Policy.evaluate(~capability=CanNavigate, ~appMode=interactiveMode, ops))
    ->Expect.toBe(true)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanEditHotspots, ~appMode=interactiveMode, ops))
    ->Expect.toBe(true)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanUpload, ~appMode=interactiveMode, ops))
    ->Expect.toBe(true)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanExport, ~appMode=interactiveMode, ops))
    ->Expect.toBe(true)
    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanMutateProject, ~appMode=interactiveMode, ops),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanStartSimulation, ~appMode=interactiveMode, ops),
    )
    ->Expect.toBe(true)
    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanInteractWithViewer, ~appMode=interactiveMode, ops),
    )
    ->Expect.toBe(true)
  })

  test("blocks capabilities when app mode is system locked", t => {
    let ops = []

    t
    ->expect(Capability.Policy.evaluate(~capability=CanNavigate, ~appMode=loadingMode, ops))
    ->Expect.toBe(false)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanUpload, ~appMode=loadingMode, ops))
    ->Expect.toBe(false)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanExport, ~appMode=loadingMode, ops))
    ->Expect.toBe(false)
  })

  test("navigation is blocked while navigation op is active", t => {
    let ops = [MockTask.make(~id="nav", ~type_=Navigation, ())]

    t
    ->expect(Capability.Policy.evaluate(~capability=CanNavigate, ~appMode=interactiveMode, ops))
    ->Expect.toBe(false)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanEditHotspots, ~appMode=interactiveMode, ops))
    ->Expect.toBe(false)
    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanInteractWithViewer, ~appMode=interactiveMode, ops),
    )
    ->Expect.toBe(false)
  })

  test("mutation locks during risky active operations", t => {
    let navOps = [MockTask.make(~id="nav", ~type_=Navigation, ())]
    let simOps = [MockTask.make(~id="sim", ~type_=Simulation, ())]
    let uploadOps = [MockTask.make(~id="up", ~type_=Upload, ())]
    let saveOps = [MockTask.make(~id="save", ~type_=ProjectSave, ())]

    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanMutateProject, ~appMode=interactiveMode, navOps),
    )
    ->Expect.toBe(false)
    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanMutateProject, ~appMode=interactiveMode, simOps),
    )
    ->Expect.toBe(false)
    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanMutateProject, ~appMode=interactiveMode, uploadOps),
    )
    ->Expect.toBe(false)
    t
    ->expect(
      Capability.Policy.evaluate(~capability=CanMutateProject, ~appMode=interactiveMode, saveOps),
    )
    ->Expect.toBe(false)
  })

  test("upload and export capabilities respect conflicting ops", t => {
    let uploadOps = [MockTask.make(~id="up", ~type_=Upload, ())]
    let exportOps = [MockTask.make(~id="exp", ~type_=Export, ())]

    t
    ->expect(Capability.Policy.evaluate(~capability=CanUpload, ~appMode=interactiveMode, uploadOps))
    ->Expect.toBe(false)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanExport, ~appMode=interactiveMode, uploadOps))
    ->Expect.toBe(false)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanExport, ~appMode=interactiveMode, exportOps))
    ->Expect.toBe(false)
  })

  test("critical operation type enforces system lock even if app mode is interactive", t => {
    let ops = [MockTask.make(~id="load", ~type_=ProjectLoad, ())]

    t->expect(Capability.Policy.isSystemLocked(~appMode=interactiveMode, ops))->Expect.toBe(true)
    t
    ->expect(Capability.Policy.evaluate(~capability=CanNavigate, ~appMode=interactiveMode, ops))
    ->Expect.toBe(false)
  })
})
