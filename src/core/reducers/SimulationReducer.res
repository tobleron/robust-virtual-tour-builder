open Types
open Actions

let reduce = (state: state, action: action): option<state> => {
  switch action {
  | StartAutoPilot(journeyId, skip) =>
    Some({
      ...state,
      simulation: {
        ...state.simulation,
        status: Running,
        // isAutoPilot: true, // REMOVED
        autoPilotJourneyId: journeyId,
        visitedScenes: [],
        skipAutoForwardGlobal: skip,
        stoppingOnArrival: false,
      },
    })
  | StopAutoPilot =>
    Some({
      ...state,
      navigation: Idle,
      currentJourneyId: state.currentJourneyId + 1,
      simulation: {
        ...state.simulation,
        status: Idle,
        // isAutoPilot: false, // REMOVED
        pendingAdvanceId: None,
        visitedScenes: [],
        stoppingOnArrival: false,
        skipAutoForwardGlobal: false,
      },
    })
  | AddVisitedScene(sceneIdx) =>
    Some({
      ...state,
      simulation: {
        ...state.simulation,
        visitedScenes: Belt.Array.concat(state.simulation.visitedScenes, [sceneIdx]),
      },
    })
  | ClearVisitedScenes =>
    Some({
      ...state,
      simulation: {
        ...state.simulation,
        visitedScenes: [],
      },
    })
  | SetStoppingOnArrival(value) =>
    Some({
      ...state,
      simulation: {
        ...state.simulation,
        stoppingOnArrival: value,
      },
    })
  | SetSkipAutoForward(value) =>
    Some({
      ...state,
      simulation: {
        ...state.simulation,
        skipAutoForwardGlobal: value,
      },
    })
  | UpdateAdvanceTime(time) =>
    Some({
      ...state,
      simulation: {
        ...state.simulation,
        lastAdvanceTime: time,
      },
    })
  | SetPendingAdvance(id) =>
    Some({
      ...state,
      simulation: {
        ...state.simulation,
        pendingAdvanceId: id,
      },
    })
  | _ => None
  }
}
