open Types

let handleStartAutoPilot = (state: state, journeyId: int, skip: bool): state => {
  {
    ...state,
    simulation: {
      ...state.simulation,
      status: Running,
      autoPilotJourneyId: journeyId,
      visitedLinkIds: [],
      skipAutoForwardGlobal: skip,
      stoppingOnArrival: false,
    },
  }
}

let handleStartLinking = (state: state, _draft: option<linkDraft>): state => {
  {
    ...state,
    navigationState: {...state.navigationState, navigation: Idle},
    simulation: {
      ...state.simulation,
      status: Idle,
      pendingAdvanceId: None,
      visitedLinkIds: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
    },
  }
}

let handleStopAutoPilot = (state: state): state => {
  {
    ...state,
    navigationState: {
      ...state.navigationState,
      navigation: Idle,
      currentJourneyId: state.navigationState.currentJourneyId + 1,
    },
    simulation: {
      ...state.simulation,
      status: Idle,
      pendingAdvanceId: None,
      visitedLinkIds: [],
      stoppingOnArrival: false,
      skipAutoForwardGlobal: false,
    },
  }
}

let handleAddVisitedLink = (state: state, linkId: string): state => {
  {
    ...state,
    simulation: {
      ...state.simulation,
      visitedLinkIds: Belt.Array.concat(state.simulation.visitedLinkIds, [linkId]),
    },
  }
}
