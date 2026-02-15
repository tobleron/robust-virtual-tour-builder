/* src/components/ViewerManager.res */

@react.component
let make = () => {
  PerfUtils.useRenderBudget("ViewerManager")
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let simSlice = AppContext.useSimSlice()
  let dispatch = AppContext.useAppDispatch()

  let getState = AppContext.getBridgeState

  // Business Logic Hooks
  ViewerManagerLifecycle.useInitialization(~getState, ~dispatch)
  ViewerManagerLogic.useSceneCleanup(~scenes=sceneSlice.scenes)
  ViewerManagerLogic.usePreloading(
    ~preloadingSceneIndex=uiSlice.preloadingSceneIndex,
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~dispatch,
  )
  ViewerManagerLogic.useMainSceneLoading(
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~isLinking=uiSlice.isLinking,
    ~activeYaw=sceneSlice.activeYaw,
    ~activePitch=sceneSlice.activePitch,
    ~getState,
    ~dispatch,
  )
  ViewerManagerLogic.useHotspotSync(
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~isLinking=uiSlice.isLinking,
    ~getState,
    ~dispatch,
  )
  ViewerManagerLogic.useRatchetState(~isLinking=uiSlice.isLinking)
  ViewerManagerLogic.useSimulationArrival(
    ~activeIndex=sceneSlice.activeIndex,
    ~simulationStatus=simSlice.simulation.status,
  )

  // Construct partial state for lifecycle hook or update it?
  // Lifecycle hook useLinkingAndSimUI uses: isLinking, simulation, navigationState(navSlice?), scenes, activeIndex.
  // I need navSlice.
  let navSlice = AppContext.useNavigationSlice()
  ViewerManagerLifecycle.useLinkingAndSimUI(
    ~isLinking=uiSlice.isLinking,
    ~simulation=simSlice.simulation,
    ~navigationState=navSlice,
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~getState,
    ~dispatch,
  )
  ViewerManagerLogic.useHotspotLineLoop(~getState, dispatch)
  ViewerManagerLogic.useIntroPan(
    ~navigationState=navSlice,
    ~activeIndex=sceneSlice.activeIndex,
    ~isLinking=uiSlice.isLinking,
    ~isTeasing=uiSlice.isTeasing,
    ~scenes=sceneSlice.scenes,
    ~simulationStatus=simSlice.simulation.status,
  )

  React.null
}
