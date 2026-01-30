/* src/systems/TeaserPathfinder.res */

type step = BackendApi.step

let getWalkPath = (scenes, skipAutoForward) =>
  BackendApi.calculatePath({type_: "walk", scenes, skipAutoForward})

let getTimelinePath = (timeline, scenes, skipAutoForward) =>
  BackendApi.calculatePath({type_: "timeline", timeline, scenes, skipAutoForward})

module Pathfinder = {
  let getWalkPath = getWalkPath
  let getTimelinePath = getTimelinePath
}
