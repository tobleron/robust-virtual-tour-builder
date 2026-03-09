open Types

let buildMockState = (
  ~inventory: Belt.Map.String.t<sceneEntry>,
  ~sceneOrder: array<string>,
  ~activeIndex: int,
  ~navigationState,
) : state => {
  {
    ...State.initialState,
    inventory,
    sceneOrder,
    activeIndex,
    navigationState,
  }
}

let taskIdOpt = (~taskInfo, ~getId) => taskInfo->Option.map(getId)

let taskSignalOpt = (~taskInfo, ~getSignal) => taskInfo->Option.map(getSignal)

let handleLoadTimeout = (
  ~taskInfo,
  ~isAnticipatory: bool,
  ~dispatch,
  ~isCurrentTask,
  ~abortTask,
) => {
  switch taskInfo {
  | Some(t) if isCurrentTask(t) =>
    if isAnticipatory {
      dispatch(Actions.DispatchNavigationFsmEvent(Reset))
    } else {
      abortTask(t)
      dispatch(Actions.DispatchNavigationFsmEvent(LoadTimeout))
    }
  | _ => ()
  }
}

let performStabilizingSwap = (
  ~scenes,
  ~targetSceneId: string,
  ~getState,
  ~dispatch,
  ~transition,
  ~getSceneId,
  ~getSceneName,
) => {
  let sceneOpt = scenes->Belt.Array.getBy(s => getSceneId(s) == targetSceneId)
  switch sceneOpt {
  | Some(ts) =>
    Logger.debug(
      ~module_="NavigationController",
      ~message="PERFORMING_SWAP",
      ~data=Some({"sceneId": getSceneId(ts), "sceneName": getSceneName(ts)}),
      (),
    )
    let current = NavigationSupervisor.getCurrentTask()
    switch current {
    | Some(t) if NavigationSupervisor.isCurrentToken(t.token) =>
      Scene.Transition.performSwap(
        ts,
        0.0,
        ~taskId=?Some(t.token.id),
        ~getState,
        ~dispatch,
        ~transition,
      )
    | _ =>
      Logger.info(
        ~module_="NavigationController",
        ~message="STABILIZING_WITHOUT_TASK_FALLBACK",
        ~data=Some({"targetSceneId": targetSceneId}),
        (),
      )
      Scene.Transition.performSwap(ts, 0.0, ~getState, ~dispatch, ~transition)
    }
  | None =>
    Logger.error(
      ~module_="NavigationController",
      ~message="STABILIZING_SCENE_NOT_FOUND",
      ~data=Some({
        "targetSceneId": targetSceneId,
        "availableScenes": scenes->Belt.Array.map(s => s.id),
      }),
      (),
    )
    NavigationSupervisor.getCurrentTask()->Option.forEach(t =>
      NavigationSupervisor.abort(t.token.id)
    )
    dispatch(Actions.DispatchNavigationFsmEvent(StabilizeComplete))
  }
}
