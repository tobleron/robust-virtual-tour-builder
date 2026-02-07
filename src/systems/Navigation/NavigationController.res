/* src/systems/Navigation/NavigationController.res */

open Types
open ReBindings
@@warning("-45")

module ControllerHooks = {
  let useNavigationFSM = (state: state, dispatch) => {
    React.useEffect3(() => {
      switch state.navigationFsm {
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
        Scene.Loader.loadNewScene(~sourceSceneId?, ~targetSceneId, ~isAnticipatory)

        let timeoutId = Window.setTimeout(() => {
          if isAnticipatory {
            dispatch(Actions.DispatchNavigationFsmEvent(Reset))
          } else {
            dispatch(Actions.DispatchNavigationFsmEvent(LoadTimeout))
          }
        }, Constants.sceneLoadTimeout)
        Some(() => Window.clearTimeout(timeoutId))
      | Transitioning({progress}) if progress == 0.0 =>
        let shouldFinalize = switch state.navigation {
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
            Scene.Transition.performSwap(ts, 0.0)
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
            // Force release lock and complete even if scene not found
            TransitionLock.release("NavigationController_NotFound")
            GlobalStateBridge.dispatch(Actions.DispatchNavigationFsmEvent(StabilizeComplete))
          }
        })
        None
      | IdleFsm =>
        switch state.navigation {
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
    }, (state.navigationFsm, state.scenes, state.activeIndex))
  }

  let useNavigationAnimation = (state: state, dispatch) => {
    let ajid = React.useRef(None)
    let req = React.useRef(None)

    React.useEffect1(() => {
      switch state.navigation {
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
              NavigationRenderer.AnimationLoop.startLoop(v, j, pd, dispatch, req)
            | None =>
              Logger.warn(~module_="NavigationController", ~message="NO_PATH_DATA_FALLBACK", ())
              dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
            }
          })
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
    }, [state.navigation])

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
  ControllerHooks.useNavigationFSM(state, dispatch)
  ControllerHooks.useNavigationAnimation(state, dispatch)
  React.null
}
