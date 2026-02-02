/* src/components/ViewerManager.res */

@react.component
let make = () => {
  let state = AppContext.useAppState()
  let {dispatch} = AppContext.useInteractionQueue()

  // Business Logic Hooks
  ViewerManagerLifecycle.useInitialization()
  ViewerManagerLogic.useSceneCleanup(state)
  ViewerManagerLogic.usePreloading(state, dispatch)
  ViewerManagerLogic.useMainSceneLoading(state, dispatch)
  ViewerManagerLogic.useHotspotSync(state, dispatch)
  ViewerManagerLogic.useRatchetState(state)
  ViewerManagerLogic.useSimulationArrival(state)
  ViewerManagerLifecycle.useLinkingAndSimUI(state, dispatch)
  ViewerManagerLogic.useHotspotLineLoop(state, dispatch)

  React.null
}
