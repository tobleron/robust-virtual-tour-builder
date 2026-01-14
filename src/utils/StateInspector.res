/**
 * StateInspector - Debug-only state exposure for development
 * 
 * This module provides controlled access to application state for debugging purposes.
 * It is automatically disabled in production builds.
 */


type stateSnapshot = {
  tourName: string,
  sceneCount: int,
  activeSceneIndex: int,
  isLinking: bool,
  isSimulationMode: bool,
  timestamp: float,
}

/**
 * Creates a safe, read-only snapshot of the current state
 * Excludes sensitive data and large objects
 */
let createSnapshot = (state: Types.state): stateSnapshot => {
  {
    tourName: state.tourName,
    sceneCount: Belt.Array.length(state.scenes),
    activeSceneIndex: state.activeIndex,
    isLinking: state.isLinking,
    isSimulationMode: state.isSimulationMode,
    timestamp: Date.now(),
  }
}

/**
 * Exposes state to window.store for debugging
 * Only active in development builds or when ENABLE_STATE_INSPECTOR=true
 */
let exposeToWindow = () => {
  if Constants.enableStateInspector() {
    let getState = GlobalStateBridge.getState
    
    let setupStore = %raw(`
      function(getState) {
        window.store = {
          // Read-only getter for state snapshot
          get state() { 
            const state = getState();
            return Object.freeze({
              tourName: state.tourName,
              sceneCount: state.scenes.length,
              activeSceneIndex: state.activeIndex,
              isLinking: state.isLinking,
              isSimulationMode: state.isSimulationMode,
              timestamp: Date.now(),
              // Add warning
              __warning: 'This is a read-only snapshot. Direct mutation will not affect app state.'
            });
          },
          
          // Helper to get full state (frozen)
          getFullState() {
            console.warn('⚠️ Accessing full state. This is for debugging only.');
            return Object.freeze(getState());
          },
          
          // Helper to log state changes
          subscribe(callback) {
            console.warn('State subscription is not implemented. Use React DevTools instead.');
            return () => {};
          }
        };
        
        // Make window.store itself read-only
        Object.freeze(window.store);
        
        console.info('🔍 State Inspector enabled. Access via window.store.state');
      }
    `)
    
    setupStore(getState)
  } else {
    // Production: No state exposure
    Logger.info(~module_="StateInspector", ~message="State inspector disabled in production", ())
  }
}

/**
 * Removes state exposure (for cleanup or security)
 */
let removeFromWindow = () => {
  let _ = %raw(`
    (function() {
      if (typeof window !== 'undefined' && window.store) {
        delete window.store;
        console.info('🔒 State Inspector removed');
      }
    })()
  `)
}
