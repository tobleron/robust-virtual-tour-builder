/* src/components/ViewerManager.res */

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let dispatch = AppContext.useAppDispatch()

  // Business Logic Hooks
  ViewerManagerLogic.useInitialization()
  ViewerManagerLogic.useSceneCleanup(state)
  ViewerManagerLogic.usePreloading(state, dispatch)
  ViewerManagerLogic.useMainSceneLoading(state, dispatch)
  ViewerManagerLogic.useHotspotSync(state, dispatch)
  ViewerManagerLogic.useRatchetState(state)
  ViewerManagerLogic.useSimulationArrival(state)
  ViewerManagerLogic.useLinkingAndSimUI(state, dispatch)
  ViewerManagerLogic.useHotspotLineLoop()

  React.null
}
