let handleLoadProject = async (
  filesOpt,
  ~getState: unit => Types.state,
  ~dispatch: Actions.action => unit,
  ~sceneCount: int,
  target,
) =>
  await SidebarProjectLoadFlow.handleLoadProject(
    filesOpt,
    ~getState,
    ~dispatch,
    ~sceneCount,
    target,
  )
