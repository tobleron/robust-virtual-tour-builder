open Types

let parseTimelineItem = (json: JSON.t): timelineItem => {
  Schemas.parse(json, Schemas.Domain.timelineItem)->Belt.Result.getWithDefault({
    id: "",
    linkId: "",
    sceneId: "",
    targetScene: "",
    transition: "fade",
    duration: 1000,
  })
}

let handleUpdateTimelineStep = (state: state, id: string, dataJson: JSON.t): state => {
  let data = Schemas.parse(dataJson, Schemas.Domain.timelineUpdate)->Belt.Result.getWithDefault({
    transition: None,
    duration: None,
  })

  let updateItem = t => {
    if t.id == id {
      {
        ...t,
        transition: data.transition->Belt.Option.getWithDefault(t.transition),
        duration: data.duration
        ->Belt.Option.flatMap(x => x)
        ->Belt.Option.getWithDefault(t.duration),
      }
    } else {
      t
    }
  }

  {...state, timeline: state.timeline->Belt.Array.map(updateItem)}
}
