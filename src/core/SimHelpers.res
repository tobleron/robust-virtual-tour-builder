open Types

let parseTimelineItem = (json: JSON.t): timelineItem => {
  let item = switch JsonTypes.decodeTimelineItem(json) {
  | Ok(i) => i
  | Error(_) =>
    (
      {
        id: "",
        linkId: "",
        sceneId: "",
        targetScene: "",
        transition: "fade",
        duration: 1000,
      }: JsonTypes.timelineItemJson
    )
  }
  {
    id: item.id,
    linkId: item.linkId,
    sceneId: item.sceneId,
    targetScene: item.targetScene,
    transition: item.transition,
    duration: item.duration,
  }
}

let handleUpdateTimelineStep = (state: state, id: string, dataJson: JSON.t): state => {
  let data = switch JsonTypes.decodeTimelineUpdate(dataJson) {
  | Ok(d) => d
  | Error(_) => ({transition: Nullable.null, duration: Nullable.null}: JsonTypes.timelineUpdateJson)
  }
  let newTimeline = Belt.Array.map(state.timeline, t => {
    if t.id == id {
      {
        ...t,
        transition: switch Nullable.toOption(data.transition) {
        | Some(tr) => tr
        | None => t.transition
        },
        duration: switch Nullable.toOption(data.duration) {
        | Some(d) => d
        | None => t.duration
        },
      }
    } else {
      t
    }
  })
  {...state, timeline: newTimeline}
}
