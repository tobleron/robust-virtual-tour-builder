external unknownToString: unknown => string = "%identity"
external unknownToBool: unknown => bool = "%identity"

let getActiveSceneId = (state: Types.state): option<string> => {
  let scenes = SceneInventory.getActiveScenes(state.inventory, state.sceneOrder)
  Belt.Array.get(scenes, state.activeIndex)->Option.map(scene => scene.id)
}

let isProjectViewerReady = (~getState: unit => Types.state): bool => {
  let state = getState()
  switch getActiveSceneId(state) {
  | None => true
  | Some(sceneId) =>
    let fsmIdle = switch state.navigationState.navigationFsm {
    | IdleFsm => true
    | _ => false
    }
    let supervisorIdle = NavigationSupervisor.isIdle()
    let viewerReady = switch ViewerSystem.getActiveViewer()->Nullable.toOption {
    | Some(viewer) =>
      let loadedSceneId =
        ViewerSystem.Adapter.getMetaData(viewer, "sceneId")
        ->Option.map(unknownToString)
        ->Option.getOr("")
      let loadedFlag =
        ViewerSystem.Adapter.getMetaData(viewer, "isLoaded")
        ->Option.map(unknownToBool)
        ->Option.getOr(false)
      loadedFlag && loadedSceneId == sceneId
    | None => false
    }
    fsmIdle && supervisorIdle && viewerReady
  }
}

let delayMs = (ms: int): Promise.t<unit> =>
  Promise.make((resolve, _reject) => {
    ignore(ReBindings.Window.setTimeout(() => resolve(), ms))
  })

let waitForProjectReady = (
  ~getState: unit => Types.state,
  ~opId: OperationLifecycle.operationId,
  ~maxWaitMs=25000,
  ~pollIntervalMs=80,
): Promise.t<result<unit, string>> => {
  let startedAt = Date.now()

  let rec poll = (): Promise.t<result<unit, string>> => {
    if isProjectViewerReady(~getState) {
      Promise.resolve(Ok())
    } else {
      let elapsed = Date.now() -. startedAt
      if elapsed >= maxWaitMs->Int.toFloat {
        Promise.resolve(Error("Viewer readiness timed out; continuing with current state."))
      } else {
        if OperationLifecycle.isActive(opId) {
          let pct = 90.0 +. Math.min(9.0, elapsed /. maxWaitMs->Int.toFloat *. 9.0)
          OperationLifecycle.progress(
            opId,
            pct,
            ~message="Finalizing viewer...",
            ~phase="Project Load",
            (),
          )
        }
        delayMs(pollIntervalMs)->Promise.then(_ => poll())
      }
    }
  }

  poll()
}
