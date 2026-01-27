open Types

let parseTimelineItem = (json: JSON.t): timelineItem => {
  switch Schemas.parse(json, Schemas.Domain.timelineItem) {
  | Ok(item) => item
  | Error(_) => {
      id: "",
      linkId: "",
      sceneId: "",
      targetScene: "",
      transition: "fade",
      duration: 1000,
    }
  }
}

let handleUpdateTimelineStep = (state: state, id: string, dataJson: JSON.t): state => {
  let data = switch Schemas.parse(dataJson, Schemas.Domain.timelineUpdate) {
  | Ok(d) => d
  | Error(_) => {transition: None, duration: None}
  }
  let newTimeline = Belt.Array.map(state.timeline, t => {
    if t.id == id {
      {
        ...t,
        transition: switch data.transition {
        | Some(tr) => tr
        | None => t.transition
        },
        duration: switch data.duration {
        | Some(Some(d)) => d
        | _ => t.duration
        },
      }
    } else {
      t
    }
  })
  {...state, timeline: newTimeline}
}
