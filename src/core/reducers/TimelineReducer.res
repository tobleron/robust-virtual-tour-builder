open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | AddToTimeline(json) =>
    let item = ReducerHelpers.parseTimelineItem(json)
    Some({...state, timeline: Belt.Array.concat(state.timeline, [item])})

  | SetActiveTimelineStep(idOpt) => Some({...state, activeTimelineStepId: idOpt})

  | RemoveFromTimeline(id) =>
    Some({...state, timeline: Belt.Array.keep(state.timeline, t => t.id != id)})

  | ReorderTimeline(fromIdx, toIdx) =>
    if fromIdx != toIdx {
      let itemOpt = Belt.Array.get(state.timeline, fromIdx)
      switch itemOpt {
      | Some(item) =>
        let rest = Belt.Array.keepWithIndex(state.timeline, (_, i) => i != fromIdx)
        let newTimeline = ReducerHelpers.insertAt(rest, toIdx, item)
        Some({...state, timeline: newTimeline})
      | None => Some(state)
      }
    } else {
      Some(state)
    }

  | UpdateTimelineStep(id, dataJson) =>
    Some(ReducerHelpers.handleUpdateTimelineStep(state, id, dataJson))

  | _ => None
  }
}
