# Task 90: Secure GlobalStateBridge and window.store

## Priority
**MEDIUM** - Security and architecture concern

## Context
`Main.res` currently exposes the entire application state via `window.store`, creating a "backdoor" that bypasses the unidirectional data flow. While useful for debugging, this poses risks if external scripts or browser console commands start mutating state.

## Current Implementation

In `Main.res` (lines 46-50):
```rescript
let _ = %raw(`
  window.store = {
    get state() { return GlobalStateBridge.getState(); }
  }
`)
```

This allows any script to access:
```javascript
window.store.state // Full application state
```

## Issues

1. **Security Risk**: External scripts or malicious browser extensions could read sensitive state data
2. **Architecture Violation**: Breaks the unidirectional data flow if anything tries to mutate this
3. **Production Overhead**: Unnecessary in production builds
4. **Debugging Dependency**: Developers might rely on this instead of proper debugging tools

## Goals

1. **Make window.store Debug-Only**: Only expose state in development builds
2. **Add Read-Only Protection**: Ensure the exposed state cannot be mutated
3. **Add Visibility Controls**: Allow toggling this feature via environment variable
4. **Document Proper Debugging**: Provide alternative debugging methods for production

## Implementation Steps

### Step 1: Add Build-Time Flag Detection

Create a utility to detect debug mode in `src/utils/Constants.res`:

```rescript
@val @scope("import.meta.env") external mode: string = "MODE"
@val @scope("import.meta.env") external isDev: bool = "DEV"

let isDebugBuild = () => {
  try {
    mode === "development" || isDev
  } catch {
  | _ => false
  }
}

let enableStateInspector = () => {
  try {
    %raw(`typeof process !== 'undefined' && process.env.ENABLE_STATE_INSPECTOR === 'true'`) || isDebugBuild()
  } catch {
  | _ => isDebugBuild()
  }
}
```

### Step 2: Create Secure State Inspector Module

Create `src/utils/StateInspector.res`:

```rescript
/**
 * StateInspector - Debug-only state exposure for development
 * 
 * This module provides controlled access to application state for debugging purposes.
 * It is automatically disabled in production builds.
 */

open ReBindings

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
    timestamp: Js.Date.now(),
  }
}

/**
 * Exposes state to window.store for debugging
 * Only active in development builds or when ENABLE_STATE_INSPECTOR=true
 */
let exposeToWindow = () => {
  if Constants.enableStateInspector() {
    let _ = %raw(`
      window.store = {
        // Read-only getter for state snapshot
        get state() { 
          const state = GlobalStateBridge.getState();
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
          return Object.freeze(GlobalStateBridge.getState());
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
    `)
    ()
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
    if (typeof window !== 'undefined' && window.store) {
      delete window.store;
      console.info('🔒 State Inspector removed');
    }
  `)
  ()
}
```

### Step 3: Update Main.res

Replace the current `window.store` setup with:

```rescript
// 2. Global JSON store access (for legacy scripts/console) - DEBUG ONLY
StateInspector.exposeToWindow()
```

### Step 4: Add Environment Variable Support

Update `.env.development` (create if it doesn't exist):
```
ENABLE_STATE_INSPECTOR=true
```

Update `.env.production` (create if it doesn't exist):
```
ENABLE_STATE_INSPECTOR=false
```

### Step 5: Document Proper Debugging Workflow

Create `docs/DEBUGGING_GUIDE.md`:

```markdown
# Debugging Guide

## Development Mode

### State Inspection

In development builds, you can inspect application state via the browser console:

```javascript
// Get a safe snapshot of current state
window.store.state

// Get full state (frozen, read-only)
window.store.getFullState()
```

**Note**: These are read-only snapshots. Mutations will not affect the application.

### Recommended Tools

1. **React DevTools**: Best for inspecting component state and props
2. **Redux DevTools**: If using Redux (currently using useReducer)
3. **Logger Module**: Check browser console for structured logs
4. **Network Tab**: Monitor backend API calls

## Production Mode

State inspector is **disabled** in production builds for security and performance.

### Debugging Production Issues

1. **Enable Telemetry Logs**: Check backend logs at `backend/backend.log`
2. **Error Tracking**: All errors are logged via `Logger.error()`
3. **Network Monitoring**: Use browser DevTools Network tab
4. **Performance Profiling**: Use Chrome DevTools Performance tab

### Emergency State Access

If you need to inspect state in production:

1. Set environment variable: `ENABLE_STATE_INSPECTOR=true`
2. Rebuild the application: `npm run build`
3. Access via `window.store.state`
4. **Remember to disable after debugging**

## Best Practices

- ❌ Don't rely on `window.store` for application logic
- ❌ Don't mutate state directly via console
- ✅ Use React DevTools for component debugging
- ✅ Use Logger module for runtime debugging
- ✅ Use unit tests for logic verification
```

### Step 6: Add Security Warning

Update `GlobalStateBridge.res` to add a warning comment:

```rescript
/**
 * GlobalStateBridge - Controlled access to application state
 * 
 * WARNING: This module provides direct access to application state.
 * It should ONLY be used by:
 * - StateInspector (debug builds)
 * - Systems that need read-only state access (AudioManager, SimulationSystem)
 * 
 * DO NOT use this for state mutations. Always dispatch actions via AppContext.
 */
```

## Verification

### Development Build
1. **Build the application**:
   ```bash
   npm run res:build
   ```

2. **Start dev server**:
   ```bash
   npm run dev
   ```

3. **Open browser console**:
   ```javascript
   window.store.state // Should return frozen snapshot
   window.store.state.tourName = "hack" // Should fail silently or throw error
   window.store.getFullState() // Should return frozen full state
   ```

4. **Verify freeze**:
   ```javascript
   Object.isFrozen(window.store) // Should be true
   Object.isFrozen(window.store.state) // Should be true
   ```

### Production Build
1. **Build for production**:
   ```bash
   npm run build
   ```

2. **Start production server**:
   ```bash
   cd backend && cargo run --release
   ```

3. **Open browser console**:
   ```javascript
   window.store // Should be undefined
   ```

### Security Test
1. Try to mutate state via console (should fail):
   ```javascript
   window.store.state = {} // Should fail
   window.store.state.tourName = "test" // Should fail
   ```

2. Verify no memory leaks from frozen objects

## Success Criteria

- [ ] `window.store` only exposed in development builds
- [ ] `window.store` and `window.store.state` are frozen (immutable)
- [ ] Production builds have no `window.store` exposure
- [ ] Environment variable `ENABLE_STATE_INSPECTOR` controls exposure
- [ ] Documentation added for proper debugging workflow
- [ ] Security warning added to `GlobalStateBridge.res`
- [ ] Console shows clear info message when inspector is enabled/disabled
- [ ] No performance impact in production builds

## Notes

- This change improves security without removing debugging capabilities
- Developers can still access state in development, but in a controlled way
- The frozen snapshots prevent accidental mutations
- Consider adding Redux DevTools integration as a future enhancement
- The `StateInspector` module can be extended with more debugging utilities
