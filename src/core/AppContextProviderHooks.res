// @efficiency-role: state-hook

open Types
open! Actions

type dispatch = action => unit

let isRafBatchableAction = (action: action): bool =>
  switch action {
  | UpdateLinkDraft(_)
  | SetPreloadingScene(_) => true
  | _ => false
  }

let loadInitialState = injectedState => {
  switch injectedState {
  | Some(state) => state
  | None =>
    switch SessionStore.loadState() {
    | Some(state) => {
        ...State.initialState,
        activeYaw: state.activeYaw,
        activePitch: state.activePitch,
        isLinking: false,
        isTeasing: false,
        tripodDeadZoneEnabled: state.tripodDeadZoneEnabled,
      }
    | None => State.initialState
    }
  }
}

let resetModuleStateForAction = nextAction => {
  switch nextAction {
  | LoadProject(_)
  | Reset =>
    Logger.info(~module_="AppContext", ~message="PERFORMING_MODULE_LEVEL_RESET", ())
    NavigationSupervisor.reset()
    ViewerState.resetState()
    StateSnapshot.clear()
    switch nextAction {
    | Reset => OperationLifecycle.reset()
    | _ => ()
    }
  | _ => ()
  }
}

let useManagedDispatch = dispatchRaw => {
  let rafIdRef = React.useRef(None)
  let queuedActionsRef = React.useRef([])

  let flushQueuedActions = () => {
    let queuedActions = queuedActionsRef.current
    queuedActionsRef.current = []
    rafIdRef.current = None
    switch Belt.Array.length(queuedActions) {
    | 0 => ()
    | 1 => dispatchRaw(queuedActions->Belt.Array.getExn(0))
    | _ => dispatchRaw(Batch(queuedActions))
    }
  }

  (nextAction: action) => {
    resetModuleStateForAction(nextAction)

    if isRafBatchableAction(nextAction) {
      queuedActionsRef.current = Belt.Array.concat(queuedActionsRef.current, [nextAction])
      switch rafIdRef.current {
      | Some(_) => ()
      | None =>
        rafIdRef.current = Some(ReBindings.Window.requestAnimationFrame(() => flushQueuedActions()))
      }
    } else {
      let currentState = AppStateBridge.getState()
      let nextState = Reducer.reducer(currentState, nextAction)
      AppStateBridge.updateState(nextState)
      dispatchRaw(nextAction)
    }
  }
}

let useLoadSessionTimeline = (dispatch: dispatch) => {
  React.useEffect0(() => {
    switch SessionStore.loadState() {
    | Some(state) =>
      switch state.timeline {
      | Some(timeline) if Array.length(timeline) > 0 => dispatch(Actions.SetTimeline(timeline))
      | _ => ()
      }
      switch state.activeTimelineStepId {
      | Some(id) => dispatch(Actions.SetActiveTimelineStep(Some(id)))
      | _ => ()
      }
    | None => ()
    }
    None
  })
}

let useSessionSlice = (state: state): Types.sessionState => {
  let sessionCore = React.useMemo7(() => {
    (
      state.tourName,
      state.activeIndex,
      state.activeYaw,
      state.activePitch,
      state.isLinking,
      state.isTeasing,
      state.tripodDeadZoneEnabled,
    )
  }, (
    state.tourName,
    state.activeIndex,
    state.activeYaw,
    state.activePitch,
    state.isLinking,
    state.isTeasing,
    state.tripodDeadZoneEnabled,
  ))

  let sessionPipeline = React.useMemo2(() => {
    (state.timeline, state.activeTimelineStepId)
  }, (state.timeline, state.activeTimelineStepId))

  React.useMemo2(() => {
    let (
      tourName,
      activeIndex,
      activeYaw,
      activePitch,
      isLinking,
      isTeasing,
      tripodDeadZoneEnabled,
    ) = sessionCore
    let (timeline, activeTimelineStepId) = sessionPipeline

    {
      tourName,
      activeIndex,
      activeYaw,
      activePitch,
      isLinking,
      isTeasing,
      tripodDeadZoneEnabled,
      timeline: Some(timeline),
      activeTimelineStepId,
    }
  }, (sessionCore, sessionPipeline))
}

let usePersistSessionSlice = (sessionSlice: Types.sessionState) => {
  React.useEffect1(() => {
    let timerId = setTimeout(() => {
      SessionStore.save(sessionSlice)
    }, 500)

    Some(
      () => {
        clearTimeout(timerId)
      },
    )
  }, [sessionSlice])
}
