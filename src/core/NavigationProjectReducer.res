/* src/core/NavigationProjectReducer.res - Navigation & Project Domain Reducers */

open Types
open Actions

module NavSync = {
  let syncNavigationFsm = (nextState: state): state => {
    switch nextState.appMode {
    | Interactive(s) => {
        ...nextState,
        navigationState: {...nextState.navigationState, navigationFsm: s.navigation},
      }
    | _ => nextState
    }
  }

  let syncNavigationFsmInAppMode = (nextState: state, nextNavState: navigationState): state => {
    switch nextState.appMode {
    | Interactive(s) => {
        ...nextState,
        appMode: Interactive({...s, navigation: nextNavState.navigationFsm}),
      }
    | _ => nextState
    }
  }
}

module Navigation = {
  let handleSimulationModeChange = (state: state, _val: bool): state => {
    let resetNavState = {
      ...state.navigationState,
      autoForwardChain: [],
      incomingLink: None,
      currentJourneyId: state.navigationState.currentJourneyId + 1,
      navigation: Idle,
    }
    {...state, navigationState: resetNavState}
  }

  let handleAppFsmEvent = (state: state, event: AppFSM.event): state => {
    let nextAppMode = AppFSM.transition(state.appMode, event)
    let nextState = {...state, appMode: nextAppMode}
    NavSync.syncNavigationFsm(nextState)
  }

  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | SetSimulationMode(val) => Some(handleSimulationModeChange(state, val))

    | AddToAutoForwardChain(idx) => Some(NavigationHelpers.handleAddToAutoForwardChain(state, idx))

    | NavigationCompleted(journey) =>
      Some(NavigationHelpers.handleNavigationCompleted(state, journey))

    | SetNavigationStatus(_)
    | SetIncomingLink(_)
    | ResetAutoForwardChain
    | IncrementJourneyId
    | SetCurrentJourneyId(_)
    | SetNavigationFsmState(_)
    | DispatchNavigationFsmEvent(_) =>
      switch NavigationState.reduce(state.navigationState, action) {
      | Some(nextNavState) => {
          let nextState = {...state, navigationState: nextNavState}

          switch action {
          | DispatchNavigationFsmEvent(_) =>
            Some(NavSync.syncNavigationFsmInAppMode(nextState, nextNavState))
          | _ => Some(nextState)
          }
        }
      | None => None
      }

    | SetPendingReturnSceneName(name) => Some({...state, pendingReturnSceneName: name})

    | DispatchAppFsmEvent(event) => Some(handleAppFsmEvent(state, event))

    | _ => None
    }
  }
}

module Project = {
  let handleLoadProject = (state: state, projectDataJson: JSON.t): state => {
    switch SceneHelpers.parseProject(projectDataJson) {
    | Ok(pd) => {
        Logger.info(
          ~module_="ReducerProject",
          ~message="PROJECT_LOADED_INTO_STATE",
          ~data=Some({
            "tourName": pd.tourName,
            "sceneCount": Array.length(SceneInventory.getActiveScenes(pd.inventory, pd.sceneOrder)),
            "inventorySize": pd.inventory->Belt.Map.String.size,
            "orderLength": Array.length(pd.sceneOrder),
          }),
          (),
        )
        let (inventoryWithSeq, nextSeqId) =
          SceneNaming.ensureSequenceIds(pd.inventory, pd.nextSceneSequenceId)

        {
          ...state,
          tourName: pd.tourName,
          inventory: inventoryWithSeq,
          sceneOrder: pd.sceneOrder,
          lastUsedCategory: pd.lastUsedCategory,
          exifReport: pd.exifReport,
          sessionId: switch pd.sessionId {
          | Some(id) => Some(id)
          | None => state.sessionId
          },
          timeline: pd.timeline,
          activeIndex: if Belt.Array.length(pd.sceneOrder) > 0 {
            0
          } else {
            -1
          },
          activeYaw: 0.0,
          activePitch: 0.0,
          navigationState: NavigationState.initial(),
          simulation: State.initialState.simulation,
          isTeasing: false,
          isLinking: false,
          linkDraft: None,
          nextSceneSequenceId: nextSeqId,
        }
      }
    | Error(e) => {
        Logger.error(
          ~module_="ReducerProject",
          ~message="PROJECT_LOAD_PARSE_FAILED",
          ~data=Some({"error": e}),
          (),
        )
        state
      }
    }
  }

  let handleRemoveDeletedSceneId = (state: state, id: string): state => {
    switch state.inventory->Belt.Map.String.get(id) {
    | Some(entry) => {
        ...state,
        inventory: state.inventory->Belt.Map.String.set(id, {...entry, status: Active}),
      }
    | None => state
    }
  }

  let reduce = (state: state, action: action): option<state> => {
    switch action {
    | SetTourName(name) => Some({...state, tourName: TourLogic.sanitizeName(name)})

    | LoadProject(projectDataJson) => Some(handleLoadProject(state, projectDataJson))

    | Actions.Reset => Some(State.initialState)

    | SetExifReport(report) => Some({...state, exifReport: Some(report)})

    | RemoveDeletedSceneId(id) => Some(handleRemoveDeletedSceneId(state, id))

    | SetSessionId(id) => Some({...state, sessionId: Some(id)})
    | SetLogo(logo) => Some({...state, logo})
    | _ => None
    }
  }
}
