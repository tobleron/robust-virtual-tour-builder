/* tests/unit/AppFSM_v.test.res */
open Vitest
open Types

test("AppFSM: toString converts modes correctly", t => {
  let init = Initializing
  t->expect(AppFSM.toString(init))->Expect.toBe("Initializing")

  let interactive = Interactive({
    uiMode: Viewing,
    navigation: IdleFsm,
    backgroundTask: None,
  })
  // Interactive(Viewing, Idle, None)
  t->expect(Js.String.includes("Viewing", AppFSM.toString(interactive)))->Expect.toBe(true)

  let blocking = SystemBlocking(CriticalError("Test Error"))
  t->expect(Js.String.includes("CriticalError", AppFSM.toString(blocking)))->Expect.toBe(true)
})

test("AppFSM: eventToString converts events correctly", t => {
  t->expect(AppFSM.eventToString(InitializeComplete))->Expect.toBe("InitializeComplete")
  t->expect(AppFSM.eventToString(StartAuthoring))->Expect.toBe("StartAuthoring")
  t->expect(AppFSM.eventToString(NavigationEvent(Reset)))->Expect.toBe("NavigationEvent")
})

test("AppFSM: Initializing -> Interactive on InitializeComplete", t => {
  let mode = Initializing
  let event = InitializeComplete
  let next = AppFSM.transition(mode, event)

  switch next {
  | Interactive({uiMode: Viewing, navigation: IdleFsm, backgroundTask: None}) =>
    t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: Initializing -> SystemBlocking on CriticalErrorOccurred", t => {
  let mode = Initializing
  let event = CriticalErrorOccurred("Init Failed")
  let next = AppFSM.transition(mode, event)

  switch next {
  | SystemBlocking(CriticalError("Init Failed")) => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: Interactive -> StartAuthoring", t => {
  let mode = Interactive({
    uiMode: Viewing,
    navigation: IdleFsm,
    backgroundTask: None,
  })
  let next = AppFSM.transition(mode, StartAuthoring)

  switch next {
  | Interactive({uiMode: EditingHotspots}) => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: Interactive -> StopAuthoring", t => {
  let mode = Interactive({
    uiMode: EditingHotspots,
    navigation: IdleFsm,
    backgroundTask: None,
  })
  let next = AppFSM.transition(mode, StopAuthoring)

  switch next {
  | Interactive({uiMode: Viewing}) => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: Interactive -> StartUpload sets background task", t => {
  let mode = Interactive({
    uiMode: Viewing,
    navigation: IdleFsm,
    backgroundTask: None,
  })
  let next = AppFSM.transition(mode, StartUpload)

  switch next {
  | Interactive({backgroundTask: Some(Uploading({progress: 0.0}))}) =>
    t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: UploadProgress updates progress", t => {
  let mode = Interactive({
    uiMode: Viewing,
    navigation: IdleFsm,
    backgroundTask: Some(Uploading({progress: 10.0})),
  })
  let next = AppFSM.transition(mode, UploadProgress(50.0))

  switch next {
  | Interactive({backgroundTask: Some(Uploading({progress: 50.0}))}) =>
    t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: UploadComplete transitions to Summary modal", t => {
  let mode = Interactive({
    uiMode: Viewing,
    navigation: IdleFsm,
    backgroundTask: Some(Uploading({progress: 100.0})),
  })

  let report: Types.uploadReport = {
    success: ["file1.jpg"],
    skipped: ["file2.jpg"],
  }

  let quality: Types.qualityItem = {
    quality: SharedTypes.defaultQuality("ok"),
    newName: "file1.jpg",
  }

  let next = AppFSM.transition(mode, UploadComplete(report, [quality]))

  switch next {
  | SystemBlocking(Summary(r, q)) => {
      t->expect(Array.length(r.success))->Expect.toBe(1)
      t->expect(Array.length(q))->Expect.toBe(1)
    }
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: ProjectLoading buffering events", t => {
  let mode = SystemBlocking(ProjectLoading({name: "Test", pendingAction: None}))
  let next = AppFSM.transition(mode, StartAuthoring)

  switch next {
  | SystemBlocking(ProjectLoading({pendingAction: Some(StartAuthoring)})) =>
    t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: ProjectLoadComplete executes pending action", t => {
  let mode = SystemBlocking(ProjectLoading({name: "Test", pendingAction: Some(StartAuthoring)}))
  let next = AppFSM.transition(mode, ProjectLoadComplete)

  // Should transition to Interactive then apply StartAuthoring
  switch next {
  | Interactive({uiMode: EditingHotspots}) => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})

test("AppFSM: CriticalError is terminal state mostly", t => {
  let mode = SystemBlocking(CriticalError("Fatal"))
  // Most events are ignored
  let next = AppFSM.transition(mode, StartAuthoring)

  switch next {
  | SystemBlocking(CriticalError("Fatal")) => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }

  // Reset should work
  let reset = AppFSM.transition(mode, Reset)
  switch reset {
  | Initializing => t->expect(true)->Expect.toBe(true)
  | _ => t->expect(false)->Expect.toBe(true)
  }
})
