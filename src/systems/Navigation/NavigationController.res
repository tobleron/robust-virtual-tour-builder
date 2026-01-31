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
      | Transitioning({progress}) if state.navigation == Idle && progress == 0.0 =>
        dispatch(Actions.DispatchNavigationFsmEvent(TransitionComplete))
      | Stabilizing({targetSceneId}) =>
        let _ = Window.requestAnimationFrame(() => {
          state.scenes
          ->Belt.Array.getBy(s => s.id == targetSceneId)
          ->Option.forEach(ts => Scene.Transition.performSwap(ts, 0.0))
        })
      | Idle =>
        switch state.navigation {
        | Navigating(j) => dispatch(NavigationCompleted(j))
        | _ => ()
        }
      | _ => ()
      }
      None
    }, [state.navigationFsm])
  }

  let useNavigationAnimation = (state: state, dispatch) => {
    let ajid = React.useRef(None)
    let req = React.useRef(None)

    React.useEffect1(() => {
      switch state.navigation {
      | Navigating(j) if ajid.current != Some(j.journeyId) =>
        ajid.current = Some(j.journeyId)
        ViewerSystem.getActiveViewer()
        ->Nullable.toOption
        ->Option.forEach(v => {
          j.pathData->Option.forEach(
            pd => {
              NavigationRenderer.AnimationLoop.startLoop(v, state, j, pd, dispatch, req)
            },
          )
        })
      | Idle =>
        ajid.current = None
        req.current->Option.forEach(id => Window.cancelAnimationFrame(id))
        req.current = None
      | _ => ()
      }
      Some(() => req.current->Option.forEach(Window.cancelAnimationFrame))
    }, [state.navigation])
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
