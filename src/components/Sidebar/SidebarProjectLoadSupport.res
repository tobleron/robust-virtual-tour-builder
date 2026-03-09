let getActiveSceneId = (state: Types.state): option<string> =>
  SidebarProjectLoadReadiness.getActiveSceneId(state)

let isProjectViewerReady = (~getState: unit => Types.state): bool =>
  SidebarProjectLoadReadiness.isProjectViewerReady(~getState)

let delayMs = (ms: int): Promise.t<unit> => SidebarProjectLoadReadiness.delayMs(ms)

let waitForProjectReady = (
  ~getState: unit => Types.state,
  ~opId: OperationLifecycle.operationId,
  ~maxWaitMs=25000,
  ~pollIntervalMs=80,
): Promise.t<result<unit, string>> =>
  SidebarProjectLoadReadiness.waitForProjectReady(~getState, ~opId, ~maxWaitMs, ~pollIntervalMs)

let handleLoadProject = async (
  filesOpt,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~sceneCount: int,
  target,
) => await SidebarProjectLoadRuntime.handleLoadProject(filesOpt, ~getState, ~dispatch, ~sceneCount, target)
