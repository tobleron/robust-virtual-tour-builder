open Types

let handleStartAutoPilot = (state: state, journeyId: int, skip: bool): state => {
  {
    ...state,
    simulation: {
      ...state.simulation,
      status: Running,
      autoPilotJourneyId: journeyId,
      visitedScenes: [],
      skipAutoForwardGlobal: skip,
      stoppingOnArrival: false,
    },
  }
}

let handleStartLinking = (state: state, _draft: option<linkDraft>): state => {
  {
    ...state,
    navigation: Idle,
    simulation: {
      ...state.simulation,
      status: Idle,
      pendingAdvanceId: None,
      visitedScenes: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
    },
  }
}

let handleStopAutoPilot = (state: state): state => {
  {
    ...state,
    navigation: Idle,
    currentJourneyId: state.currentJourneyId + 1,
    simulation: {
      ...state.simulation,
      status: Idle,
      pendingAdvanceId: None,
      visitedScenes: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
    },
  }
}

let handleAddVisitedScene = (state: state, sceneIdx: int): state => {
  {
    ...state,
    simulation: {
      ...state.simulation,
      visitedScenes: Belt.Array.concat(state.simulation.visitedScenes, [sceneIdx]),
    },
  }
}
