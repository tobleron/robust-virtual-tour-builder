/* src/systems/Navigation/NavigationController.res */

open Types
open ReBindings
open NavigationFSM
@@warning("-45")

module ControllerHooks = {
  let useNavigationFSM = (state: state, dispatch) => {
    React.useEffect1(() => {
      switch state.navigationFsm {
      | Preloading({targetSceneId, isAnticipatory}) =>
        state.scenes
        ->Belt.Array.getIndexBy(s => s.id == targetSceneId)
        ->Option.forEach(idx => {
          let prevIndex = state.activeIndex >= 0 ? Some(state.activeIndex) : None
          Scene.Loader.loadNewScene(prevIndex, Some(idx), ~isAnticipatory)
        })
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
        let _ = Window.requestAnimationFrame(() => {
          state.scenes
          ->Belt.Array.getBy(s => s.id == targetSceneId)
          ->Option.forEach(ts => Scene.Transition.performSwap(ts, 0.0))
        })
        None
      | Idle =>
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
    }, [state.navigationFsm])
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
          ViewerSystem.getActiveViewer()
          ->Nullable.toOption
          ->Option.forEach(v => {
            switch j.pathData {
            | Some(pd) => NavigationRenderer.AnimationLoop.startLoop(v, j, pd, dispatch, req)
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
