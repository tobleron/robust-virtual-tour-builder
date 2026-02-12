/* src/systems/Navigation/NavigationController.res */

open Types
open ReBindings
open React
@@warning("-45")

module ControllerHooks = {
  let useNavigationFSM = (state: state, dispatch, getState) => {
    React.useEffect2(() => {
      switch state.navigationState.navigationFsm {
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
        let sourceSceneId = state.scenes->Belt.Array.get(state.activeIndex)->Option.map(s => s.id)
        let taskInfo = NavigationSupervisor.getCurrentTask()

        Scene.Loader.loadNewScene(
          ~state=Scene.Loader.toPathRequest(state),
          ~dispatch,
          ~sourceSceneId?,
          ~targetSceneId,
          ~isAnticipatory,
          ~taskId=?taskInfo->Option.map(t => t.token.id),
          ~signal=?taskInfo->Option.map(t => t.token.signal),
        )

        let timeoutId = Window.setTimeout(() => {
          if isAnticipatory {
            dispatch(Actions.DispatchNavigationFsmEvent(Reset))
          } else {
            dispatch(Actions.DispatchNavigationFsmEvent(LoadTimeout))
          }
        }, Constants.sceneLoadTimeout)
        Some(() => Window.clearTimeout(timeoutId))
      | Transitioning({progress}) if progress == 0.0 =>
        let shouldFinalize = switch state.navigationState.navigation {
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
        let _ = Window.requestAnimationFrame(() => {
          let sceneOpt = state.scenes->Belt.Array.getBy(s => s.id == targetSceneId)
          switch sceneOpt {
          | Some(ts) =>
            Logger.debug(
              ~module_="NavigationController",
              ~message="PERFORMING_SWAP",
              ~data=Some({"sceneId": ts.id, "sceneName": ts.name}),
              (),
            )
            let taskInfo = NavigationSupervisor.getCurrentTask()
            Scene.Transition.performSwap(
              ts,
              0.0,
              ~taskId=?taskInfo->Option.map(t => t.token.id),
              ~getState,
              ~dispatch,
              ~transition=state.transition,
            )
          | None =>
            Logger.error(
              ~module_="NavigationController",
              ~message="STABILIZING_SCENE_NOT_FOUND",
              ~data=Some({
                "targetSceneId": targetSceneId,
                "availableScenes": state.scenes->Belt.Array.map(s => s.id),
              }),
              (),
            )
            // Abort task if in Supervisor mode
            let taskInfo = NavigationSupervisor.getCurrentTask()
            switch taskInfo {
            | Some(t) => NavigationSupervisor.abort(t.token.id)
            | None => ()
            }
            dispatch(Actions.DispatchNavigationFsmEvent(StabilizeComplete))
          }
        })
        None
      | IdleFsm =>
        switch state.navigationState.navigation {
        | Navigating(j) =>
          Logger.info(
            ~module_="NavigationController",
            ~message="JOURNEY_COMPLETED_DISPATCH",
            ~data=Some({"journeyId": j.journeyId}),
            (),
          )
          dispatch(NavigationCompleted(j))
        | _ => ()
        }
        None
      | _ => None
      }
    }, (state.navigationState.navigationFsm, state.activeIndex))
  }

  let useNavigationAnimation = (state: state, dispatch, getState) => {
    let ajid = React.useRef(None)
    let req = React.useRef(None)

    React.useEffect1(() => {
      switch state.navigationState.navigation {
      | Navigating(j) =>
        if ajid.current != Some(j.journeyId) {
          // NEW JOURNEY DETECTED: Cancel previous and start new
          req.current->Option.forEach(id => Window.cancelAnimationFrame(id))

          ajid.current = Some(j.journeyId)
          Logger.debug(
            ~module_="NavigationController",
            ~message="START_JOURNEY_ANIMATION",
            ~data=Some({"journeyId": j.journeyId}),
            (),
          )
          let viewerOpt = ViewerSystem.getActiveViewer()->Nullable.toOption
          Logger.debug(
            ~module_="NavigationController",
            ~message="VIEWER_CHECK_FOR_ANIMATION",
            ~data=Some({
              "journeyId": j.journeyId,
              "hasViewer": viewerOpt->Option.isSome,
              "hasPathData": j.pathData->Option.isSome,
            }),
            (),
          )
          viewerOpt->Option.forEach(v => {
            switch j.pathData {
            | Some(pd) =>
              Logger.debug(
                ~module_="NavigationController",
                ~message="STARTING_ANIMATION_LOOP",
                ~data=Some({"journeyId": j.journeyId}),
                (),
              )
              NavigationRenderer.AnimationLoop.startLoop(v, j, pd, getState, dispatch, req)
            | None =>
              Logger.warn(~module_="NavigationController", ~message="NO_PATH_DATA_FALLBACK", ())
              dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
            }
          })

          if viewerOpt->Option.isNone {
            Logger.warn(
              ~module_="NavigationController",
              ~message="NO_ACTIVE_VIEWER_FALLBACK",
              ~data=Some({
                "journeyId": j.journeyId,
                "hasPathData": j.pathData->Option.isSome,
              }),
              (),
            )
            dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
          }
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
    }, [state.navigationState.navigation])

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
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()
  let stateRef = React.useRef(state)
  React.useEffect1(() => {
    stateRef.current = state
    None
  }, [state])
  let getState = () => stateRef.current
  ControllerHooks.useNavigationFSM(state, dispatch, getState)
  ControllerHooks.useNavigationAnimation(state, dispatch, getState)
  React.null
}
