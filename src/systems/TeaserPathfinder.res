/* src/systems/TeaserPathfinder.res */

type step = BackendApi.step

let getWalkPath = (scenes, skipAutoForward, ~signal: option<BrowserBindings.AbortSignal.t>=?) =>
  BackendApi.calculatePath(~signal?, {type_: "walk", scenes, skipAutoForward, timeline: None})

let getTimelinePath = (
  timeline,
  scenes,
  skipAutoForward,
  ~signal: option<BrowserBindings.AbortSignal.t>=?,
) =>
  BackendApi.calculatePath(
    ~signal?,
    {type_: "timeline", scenes, skipAutoForward, timeline: Some(timeline)},
  )

module Pathfinder = {
  let getWalkPath = getWalkPath
  let getTimelinePath = getTimelinePath
}
