/**
 * StateInspector - Debug-only state exposure for development
 * 
 * This module provides controlled access to application state for debugging purposes.
 * It is automatically disabled in production builds.
 */
type stateUiSnapshot = {isLinking: bool}

type stateSimSnapshot = {status: string}
type stateSnapshot = {
  tourName: string,
  sceneCount: int,
  activeSceneIndex: int,
  isLinking: bool,
  ui: stateUiSnapshot,
  simulation: stateSimSnapshot,
  navigationSupervisor: string,
  timestamp: float,
}

/**
 * Creates a safe, read-only snapshot of the current state
 * Excludes sensitive data and large objects
 */
let createSnapshot = (state: Types.state): stateSnapshot => {
  {
    tourName: state.tourName,
    sceneCount: Belt.Array.length(
      SceneInventory.getActiveScenes(state.inventory, state.sceneOrder),
    ),
    activeSceneIndex: state.activeIndex,
    isLinking: state.isLinking,
    ui: {
      isLinking: state.isLinking,
    },
    simulation: {
      status: switch state.simulation.status {
      | Running => "Running"
      | Idle => "Idle"
      | Paused => "Paused"
      | Stopping => "Stopping"
      },
    },
    navigationSupervisor: NavigationSupervisor.statusToString(NavigationSupervisor.getStatus()),
    timestamp: Date.now(),
  }
}

let getDebugSnapshot = () => {
  createSnapshot(AppContext.getBridgeState())
}

/**
 * Exposes state to window.store for debugging
 * Only active in development builds or when ENABLE_STATE_INSPECTOR=true
 */
let exposeToWindow = () => {
  if Constants.enableStateInspector() {
    let getState = AppContext.getBridgeState
    let loadProject = data => {
      Logger.info(~module_="StateInspector", ~message="HEADLESS_LOAD_START", ())
      AppContext.getBridgeDispatch()(Actions.LoadProject(data))
    }
    let getSnapshot = getDebugSnapshot
    let getCircuitBreakerSnapshots = () => CircuitBreakerRegistry.getSnapshots()

    let setupStore = %raw(`
      function(getState, loadProject, getSnapshot, getCircuitBreakerSnapshots, logWarn, logInfo) {
        window.store = {
          // Read-only getter for state snapshot
          get state() { 
            return getSnapshot();
          },
          
          // Helper to get full state (frozen)
          getFullState() {
            logWarn('ACCESSING_FULL_STATE_DEBUG_ONLY');
            return Object.freeze(getState());
          },

          // Compatibility for E2E tests
          getState() {
            return getState();
          },
          
          // Helper to log state changes
          subscribe(callback) {
            logWarn('STATE_SUBSCRIPTION_NOT_IMPLEMENTED_USE_REACT_DEVTOOLS');
            return () => {};
          },

          // Payload loader for headless automation
          loadProject(data) {
            loadProject(data);
          },

          // Circuit breaker diagnostics (domain state + bulkhead usage)
          getCircuitBreakerSnapshots() {
            return getCircuitBreakerSnapshots();
          }
        };
        
        // Alias for compatibility
        window.STORE = window.store;

        // Make window.store itself read-only
        Object.freeze(window.store);
        
        logInfo('STATE_INSPECTOR_ENABLED_ACCESS_WINDOW_STORE_STATE');
      }
    `)

    setupStore(
      getState,
      loadProject,
      getSnapshot,
      getCircuitBreakerSnapshots,
      message => Logger.warn(~module_="StateInspector", ~message, ()),
      message => Logger.info(~module_="StateInspector", ~message, ()),
    )
  } else {
    // Production: No state exposure
    Logger.info(~module_="StateInspector", ~message="State inspector disabled in production", ())
  }
}

/**
 * Removes state exposure (for cleanup or security)
 */
let removeFromWindow = () => {
  let removeStore: (string => unit) => unit = %raw(`
    function(logInfo) {
      if (typeof window !== 'undefined' && window.store) {
        delete window.store;
        logInfo('STATE_INSPECTOR_REMOVED');
      }
    }
  `)
  removeStore(message => Logger.info(~module_="StateInspector", ~message, ()))
}
