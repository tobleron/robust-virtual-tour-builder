/* src/components/ViewerManager.res */

open React

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

  // Business Logic Hooks
  ViewerManagerLifecycle.useInitialization(~getState, ~dispatch)
  ViewerManagerLogic.useSceneCleanup(state)
  ViewerManagerLogic.usePreloading(state, dispatch)
  ViewerManagerLogic.useMainSceneLoading(state, dispatch)
  ViewerManagerLogic.useHotspotSync(state, dispatch)
  ViewerManagerLogic.useRatchetState(state)
  ViewerManagerLogic.useSimulationArrival(state)
  ViewerManagerLifecycle.useLinkingAndSimUI(state, dispatch)
  ViewerManagerLogic.useHotspotLineLoop(~getState, dispatch)
  ViewerManagerLogic.useIntroPan(state)

  React.null
}
