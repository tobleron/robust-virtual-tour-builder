/* src/systems/TeaserPathfinder.res */

type step = BackendApi.step

let getWalkPath = (scenes, skipAutoForward) =>
  BackendApi.calculatePath({type_: "walk", scenes, skipAutoForward, timeline: None})

let getTimelinePath = (timeline, scenes, skipAutoForward) =>
  BackendApi.calculatePath({type_: "timeline", scenes, skipAutoForward, timeline: Some(timeline)})

module Pathfinder = {
  let getWalkPath = getWalkPath
  let getTimelinePath = getTimelinePath
}
