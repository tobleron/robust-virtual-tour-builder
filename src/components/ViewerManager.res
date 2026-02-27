/* src/components/ViewerManager.res */

@react.component
let make = () => {
  PerfUtils.useRenderBudget("ViewerManager")
  let state = AppContext.useAppState()
  let sceneSlice = AppContext.useSceneSlice()
  let uiSlice = AppContext.useUiSlice()
  let simSlice = AppContext.useSimSlice()
  let dispatch = AppContext.useAppDispatch()

  let getState = AppContext.getBridgeState

  // Business Logic Hooks
  ViewerManagerLifecycle.useInitialization(~getState, ~dispatch)
  ViewerManagerCleanup.useSceneCleanup(~scenes=sceneSlice.scenes)
  ViewerManagerPreloading.usePreloading(
    ~preloadingSceneIndex=uiSlice.preloadingSceneIndex,
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~dispatch,
  )
  ViewerManagerSceneLoad.useMainSceneLoading(
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~isLinking=uiSlice.isLinking,
    ~activeYaw=sceneSlice.activeYaw,
    ~activePitch=sceneSlice.activePitch,
    ~getState,
    ~dispatch,
  )
  ViewerManagerHotspots.useHotspotSync(
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~isLinking=uiSlice.isLinking,
    ~isTeasing=uiSlice.isTeasing,
    ~getState,
    ~dispatch,
  )
  ViewerManagerRatchet.useRatchetState(~isLinking=uiSlice.isLinking)
  ViewerManagerSimulation.useSimulationArrival(
    ~activeIndex=sceneSlice.activeIndex,
    ~simulationStatus=simSlice.simulation.status,
  )

  // Construct partial state for lifecycle hook or update it?
  // Lifecycle hook useLinkingAndSimUI uses: isLinking, simulation, navigationState(navSlice?), scenes, activeIndex.
  // I need navSlice.
  let navSlice = AppContext.useNavigationSlice()
  ViewerManagerLifecycle.useLinkingAndSimUI(
    ~isLinking=uiSlice.isLinking,
    ~isTeasing=uiSlice.isTeasing,
    ~simulation=simSlice.simulation,
    ~navigationState=navSlice,
    ~scenes=sceneSlice.scenes,
    ~activeIndex=sceneSlice.activeIndex,
    ~getState,
    ~dispatch,
  )
  ViewerManagerHotspots.useHotspotLineLoop(~getState, dispatch)
  ViewerManagerIntro.useIntroPan(
    ~navigationState=navSlice,
    ~activeIndex=sceneSlice.activeIndex,
    ~isLinking=uiSlice.isLinking,
    ~isTeasing=uiSlice.isTeasing,
    ~scenes=sceneSlice.scenes,
    ~simulationStatus=simSlice.simulation.status,
  )
  PreloadManager.usePredictivePreload(~state, ~dispatch)

  React.null
}
