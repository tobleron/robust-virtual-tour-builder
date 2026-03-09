open Actions
open VisualPipelineNavigation

let handleNodeActivate = (
  ~isSystemLocked: bool,
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~dispatch,
  itemId: string,
) => {
  if isSystemLocked {
    ()
  } else {
    let nodeOpt = displayNodes->Belt.Array.getBy(node => node.id == itemId)
    switch nodeOpt {
    | Some(node) =>
      dispatch(Actions.SetActiveTimelineStep(node.timelineId))
      Logger.debug(
        ~module_="VisualPipeline",
        ~message="ACTIVATE_NODE",
        ~data=Some({
          "id": itemId,
          "timelineId": node.timelineId->Option.getOr(""),
          "targetSceneId": node.representedSceneId,
          "sourceSceneId": node.sourceSceneId,
        }),
        (),
      )
      goToScene(node.representedSceneId)
    | None =>
      Logger.warn(
        ~module_="VisualPipeline",
        ~message="ACTIVATE_NODE_UNKNOWN_STEP",
        ~data=Some({"id": itemId}),
        (),
      )
    }
  }
}

let handleNodeRemove = (
  ~isSystemLocked: bool,
  ~displayNodes: array<VisualPipelineGraph.node>,
  ~dispatch,
  itemId: string,
) => {
  if isSystemLocked {
    ()
  } else {
    switch displayNodes->Belt.Array.getBy(node => node.id == itemId) {
    | Some({timelineId: Some(timelineId)}) =>
      Logger.info(
        ~module_="VisualPipeline",
        ~message="REMOVE_STEP",
        ~data=Some({"id": itemId, "timelineId": timelineId}),
        (),
      )
      dispatch(RemoveFromTimeline(timelineId))
    | _ => ()
    }
  }
}
