/* src/systems/Navigation/NavigationController.res */

open Types
open ReBindings
open React
@@warning("-45")

module ControllerHooks = {
  let useNavigationFSM = (
    ~inventory: Belt.Map.String.t<sceneEntry>,
    ~sceneOrder: array<string>,
    ~activeIndex,
    ~navigationState,
    ~transition,
    ~dispatch,
    ~getState,
  ) => {
    React.useEffect2(() => {
      let scenes = SceneInventory.getActiveScenes(inventory, sceneOrder)
      let taskInfo = NavigationSupervisor.getCurrentTask()
      switch navigationState.navigationFsm {
      | Preloading({targetSceneId, isAnticipatory}) =>
        Logger.debug(
          ~module_="NavigationController",
          ~message="FSM_PRELOADING_ENTERED",
          ~data=Some({
            "targetSceneId": targetSceneId,
            "isAnticipatory": isAnticipatory,
          }),
          (),
        )
        let sourceSceneId = scenes->Belt.Array.get(activeIndex)->Option.map(s => s.id)
        let mockState = NavigationControllerRuntime.buildMockState(
          ~inventory,
          ~sceneOrder,
          ~activeIndex,
          ~navigationState,
        )

        Scene.Loader.loadNewScene(
          ~state=mockState,
          ~dispatch,
          ~sourceSceneId?,
          ~targetSceneId,
          ~isAnticipatory,
          ~taskId=?NavigationControllerRuntime.taskIdOpt(~taskInfo, ~getId=t => t.token.id),
          ~signal=?NavigationControllerRuntime.taskSignalOpt(~taskInfo, ~getSignal=t =>
            t.token.signal
          ),
        )

        let timeoutId = Window.setTimeout(() => {
          NavigationControllerRuntime.handleLoadTimeout(
            ~taskInfo,
            ~isAnticipatory,
            ~dispatch,
            ~isCurrentTask=t => NavigationSupervisor.isCurrentToken(t.token),
            ~abortTask=t => NavigationSupervisor.abort(t.token.id),
          )
        }, Constants.sceneLoadTimeout)
        Some(() => Window.clearTimeout(timeoutId))
      | Transitioning({progress, isPreview: _isPreview}) if progress == 0.0 =>
        let shouldFinalize = switch navigationState.navigation {
        | Idle => true
        | Navigating(j) if j.pathData == None => true
        | _ => false
        }
        if shouldFinalize {
          dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
        }
        None
      | Stabilizing({targetSceneId}) =>
        Logger.debug(
          ~module_="NavigationController",
          ~message="STABILIZING_STATE_ENTERED",
          ~data=Some({"targetSceneId": targetSceneId}),
          (),
        )
        let _ = Window.requestAnimationFrame(() =>
          NavigationControllerRuntime.performStabilizingSwap(
            ~scenes,
            ~targetSceneId,
            ~getState,
            ~dispatch,
            ~transition,
            ~getSceneId=s => s.id,
            ~getSceneName=s => s.name,
          )
        )
        None
      | IdleFsm =>
        switch navigationState.navigation {
        | Navigating(j) =>
          Logger.debug(
            ~module_="NavigationController",
            ~message="JOURNEY_COMPLETED_DISPATCH",
            ~data=Some({"journeyId": j.journeyId}),
            (),
          )
          if j.previewOnly {
            NavigationSupervisor.getCurrentTask()->Option.forEach(t => {
              if NavigationSupervisor.isCurrentToken(t.token) {
                NavigationSupervisor.complete(t.token.id)
              }
            })
          }
          dispatch(NavigationCompleted(j))
        | _ => ()
        }
        None
      | _ => None
      }
    }, (navigationState.navigationFsm, activeIndex))
  }

  let useNavigationAnimation = (~navigationStatus, ~dispatch, ~getState) => {
    let ajid = React.useRef(None)
    let req = React.useRef(None)

    React.useEffect1(() => {
      switch navigationStatus {
      | Navigating(j) =>
        if ajid.current != Some(j.journeyId) {
          req.current->Option.forEach(id => Window.cancelAnimationFrame(id))
          ajid.current = Some(j.journeyId)
          NavigationControllerAnimation.handleJourneyAnimation(
            ~journey=j,
            ~dispatch,
            ~getState,
            ~req,
          )
        }
      | Idle =>
        if ajid.current != None {
          Logger.debug(~module_="NavigationController", ~message="NAVIGATION_IDLE", ())
          ajid.current = None
          req.current->Option.forEach(id => Window.cancelAnimationFrame(id))
          req.current = None
        }
      | _ => ()
      }
      None
    }, [navigationStatus])

    // Cleanup ONLY on unmount to prevent ghost animations
    React.useEffect0(() => {
      Some(
        () => {
          if ajid.current != None {
            Logger.debug(
              ~module_="NavigationController",
              ~message="ANIMATION_UNMOUNT_CLEANUP",
              ~data=Some({"journeyId": ajid.current}),
              (),
            )
          }
          req.current->Option.forEach(id => Window.cancelAnimationFrame(id))
        },
      )
    })
  }
}

@react.component
let make = () => {
  let sceneSlice = AppContext.useSceneSlice()
  let navSlice = AppContext.useNavigationSlice()
  let state = AppContext.useAppState() // Still need state for Transition and some helpers
  let dispatch = AppContext.useAppDispatch()
  let stateRef = React.useRef(state)
  React.useEffect1(() => {
    stateRef.current = state
    None
  }, [state])
  let getState = () => stateRef.current
  ControllerHooks.useNavigationFSM(
    ~inventory=state.inventory,
    ~sceneOrder=state.sceneOrder,
    ~activeIndex=sceneSlice.activeIndex,
    ~navigationState=navSlice,
    ~transition=state.transition,
    ~dispatch,
    ~getState,
  )
  ControllerHooks.useNavigationAnimation(
    ~navigationStatus=navSlice.navigation,
    ~dispatch,
    ~getState,
  )
  React.null
}
