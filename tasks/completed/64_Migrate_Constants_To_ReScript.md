# Task 64: Migrate Constants.js to Constants.res

**Status:** Pending  
**Priority:** LOW  
**Category:** Frontend Type Safety  
**Estimated Effort:** 1-2 hours

---

## Objective

Migrate `src/constants.js` to `src/utils/Constants.res` for full type safety, compile-time checking, and better tree-shaking.

---

## Context

**Current State:**
- `src/constants.js` is a JavaScript file with 347 lines of constants
- Used throughout the codebase via `@module` bindings
- No compile-time type checking
- No guarantee values are correctly imported

**Benefits of Migration:**
1. **Type Safety:** ReScript compiler validates all references
2. **Dead Code Elimination:** Unused constants removed at compile time
3. **Autocomplete:** Editor shows available constants
4. **Refactoring Safety:** Renaming constants updates all usages
5. **Documentation:** Types serve as inline documentation

---

## Requirements

### Functional Requirements
1. Create `src/utils/Constants.res` with all constants
2. Update all imports across the codebase
3. Maintain exact same values (no behavior changes)
4. Delete `src/constants.js` when migration complete
5. Verify no runtime errors

### Technical Requirements
1. Use appropriate ReScript types (int, float, string, bool)
2. Group related constants in modules
3. Export only what's actually used
4. Add JSDoc-style comments for complex constants
5. Follow naming conventions (camelCase)

---

## Implementation Steps

### Step 1: Create `src/utils/Constants.res`

```rescript
/**
 * Application-wide constants
 * Centralizing magic numbers for better maintainability
 */

// ===========================================
// DEBUG CONFIGURATION
// ===========================================

let debugEnabledDefault = false
let debugLogLevel = "info"
let debugMaxEntries = 500
let perfWarnThreshold = 500.0 // ms
let perfInfoThreshold = 100.0 // ms

// ===========================================
// HOTSPOT CONFIGURATION
// ===========================================

let hotspotVisualOffsetDegrees = 15.0
let returnLinkDefaultPitch = 0.0
let returnLinkDisplayOffset = -15.0

// ===========================================
// VIEWER CONFIGURATION
// ===========================================

let globalHfov = 90.0

// ===========================================
// TEASER SYSTEM CONFIGURATION
// ===========================================

module Teaser = {
  let canvasWidth = 1920
  let canvasHeight = 1080
  let frameRate = 60
  
  module StyleDissolve = {
    let clipDuration = 2000
    let transitionDuration = 1000
    let cameraPanOffset = 8.0
  }
  
  module StylePunchy = {
    let clipDuration = 1200
    let transitionDuration = 200
    let cameraPanOffset = 0.0
  }
  
  module Logo = {
    let width = 150
    let padding = 30
    let borderRadius = 12
  }
}

let webpQuality = 0.92

// ===========================================
// IMAGE PROCESSING
// ===========================================

let processedImageWidth = 4096
let imageResizeQuality = "high"

// ===========================================
// PROGRESS BAR
// ===========================================

let progressBarAutoHideDelay = 2400

// ===========================================
// NOTIFICATION SYSTEM
// ===========================================

let toastDisplayDuration = 4000
let toastAnimationDuration = 400

// ===========================================
// DOWNLOAD SYSTEM
// ===========================================

let blobUrlCleanupDelay = 60000

// ===========================================
// FFMPEG CONFIGURATION
// ===========================================

module FFmpeg = {
  let crfQuality = 18
  let preset = "medium"
  let coreVersion = "0.12.10"
}

// ===========================================
// PROJECT MANAGEMENT
// ===========================================

let zipCompressionLevel = 6
let uiYieldDelay = 10

// ===========================================
// ANIMATION TIMING
// ===========================================

let modalFadeDuration = 100
let panningVelocity = 9.0
let panningMinDuration = 1500
let panningMaxDuration = 6000
let sceneStabilizationDelay = 1000
let viewerLoadCheckInterval = 100

// ===========================================
// SCENE ORGANIZATION
// ===========================================

module Scene = {
  module Categories = {
    let indoor = "indoor"
    let outdoor = "outdoor"
  }
  
  type floorLevel = {
    id: string,
    label: string,
    short: string,
    suffix: option<string>,
  }
  
  let floorLevels: array<floorLevel> = [
    {id: "b2", label: "Basement 2", short: "B", suffix: Some("-2")},
    {id: "b1", label: "Basement 1", short: "B", suffix: Some("-1")},
    {id: "ground", label: "Ground Floor", short: "G", suffix: None},
    {id: "first", label: "First Floor", short: "+1", suffix: None},
    {id: "second", label: "Second Floor", short: "+2", suffix: None},
    {id: "third", label: "Third Floor", short: "+3", suffix: None},
    {id: "fourth", label: "Fourth Floor", short: "+4", suffix: None},
    {id: "roof", label: "Roof Top", short: "R", suffix: None},
  ]
  
  module Defaults = {
    let category = "indoor"
    let floor = "ground"
    let label = ""
    let description = ""
  }
  
  module RoomLabels = {
    let outdoor = [
      "Zoom Out View", "Street View", "Entrance", "Front Yard", "Backyard",
      "Right Side", "Left Side", "Garden", "Pool Area", "Gazebo",
      "BBQ Area", "Terrace", "Driver's Room", "Garage", "Carport"
    ]
    
    let indoor = [
      "Entrance Hall", "Majlis", "Family Living", "Formal Living", "Dining Room",
      "Kitchen", "Dirty Kitchen", "Pantry", "Hallway", "Staircase",
      "Elevator Lobby", "Master Bedroom", "Bedroom", "Guest Room",
      "Bathroom", "Powder Room", "Office", "Study", "Home Cinema",
      "Gym", "Maid's Room", "Laundry Room", "Storage", "Balcony", "Roof"
    ]
  }
}

// ===========================================
// BACKEND CONFIGURATION
// ===========================================

let backendUrl = "http://localhost:8080"

// ===========================================
// NAVIGATION & SIMULATION
// ===========================================

let blinkDurationPreview = 1200
let blinkDurationSimulation = 600
let blinkRatePreview = 300
let blinkRateSimulation = 150
let idleSnapshotDelay = 2000
let sceneLoadTimeout = 10000
```

### Step 2: Update Import Statements Across Codebase

Find all files using `@module("../constants.js")` or `@module("./constants.js")`:

```bash
rg "@module.*constants.js" src/
```

For each file, replace:

**Before:**
```rescript
@module("../constants.js") external backendUrl: string = "BACKEND_URL"
@module("../constants.js") external globalHfov: float = "GLOBAL_HFOV"
```

**After:**
```rescript
// Just use Constants module directly
let url = Constants.backendUrl
let hfov = Constants.globalHfov
```

### Step 3: Update Specific Files

#### `src/systems/BackendApi.res`
**Before:**
```rescript
@module("../constants.js") external backendUrl: string = "BACKEND_URL"
```

**After:**
```rescript
// Direct import - no bindings needed
open Constants
// Use: backendUrl
```

#### `src/systems/ExifParser.res`
**Before:**
```rescript
@module("../constants.js") external backendUrl: string = "BACKEND_URL"
```

**After:**
```rescript
// Use Constants.backendUrl directly
```

#### `src/systems/TeaserRecorder.res`
**Before:**
```rescript
@module("../constants.js") external teaserCanvasWidth: int = "TEASER_CANVAS_WIDTH"
@module("../constants.js") external teaserCanvasHeight: int = "TEASER_CANVAS_HEIGHT"
```

**After:**
```rescript
let width = Constants.Teaser.canvasWidth
let height = Constants.Teaser.canvasHeight
```

#### `src/systems/Navigation.res`
**Before:**
```rescript
@module("../constants.js") external panningVelocity: float = "PANNING_VELOCITY"
```

**After:**
```rescript
let velocity = Constants.panningVelocity
```

### Step 4: Handle Complex Constants

For objects like `TEASER_STYLE_DISSOLVE`:

**Before (JS):**
```javascript
export const TEASER_STYLE_DISSOLVE = {
  clipDuration: 2000,
  transitionDuration: 1000,
  cameraPanOffset: 8,
};
```

**After (ReScript):**
```rescript
module Teaser = {
  module StyleDissolve = {
    let clipDuration = 2000
    let transitionDuration = 1000
    let cameraPanOffset = 8.0
  }
}

// Usage:
let dur = Constants.Teaser.StyleDissolve.clipDuration
```

### Step 5: Compile and Fix Errors

Run compilation:
```bash
npm run res:build
```

For each error:
1. Identify the missing constant
2. Update import to use `Constants` module
3. Recompile

### Step 6: Delete Old Constants File

Once all imports updated and compilation succeeds:
```bash
rm src/constants.js
```

### Step 7: Update `rescript.json` (if needed)

Ensure no explicit references to `constants.js` in configuration.

---

## Testing Criteria

### Compilation Tests
1. ✅ `npm run res:build` completes with no errors
2. ✅ No warnings about unused constants
3. ✅ Bundle size similar or smaller (better tree-shaking)

### Runtime Tests
1. ✅ Backend URL resolves correctly
2. ✅ HFov value in viewer matches expected (90°)
3. ✅ Teaser canvas dimensions correct (1920x1080)
4. ✅ Animation timings unchanged
5. ✅ Scene labels populate correctly

### Manual Verification
1. Load project
2. Navigate between scenes (verify panning velocity)
3. Start teaser recording (verify canvas size)
4. Upload images (verify processing)
5. Check all notifications (verify durations)

---

## Expected Impact

**Type Safety:**
- ✅ All constant references checked at compile time
- ✅ Typos in constant names caught before runtime
- ✅ Invalid types prevented (e.g., string where number expected)

**Developer Experience:**
- ✅ Autocomplete for all constants in editor
- ✅ Go-to-definition works
- ✅ Refactoring constants is safe (all usages updated)

**Bundle Size:**
- ✅ Unused constants removed automatically
- ✅ Better dead code elimination

**Maintainability:**
- ✅ Single source of truth in ReScript
- ✅ Types serve as documentation
- ✅ Easier to see what's actually used

---

## Migration Checklist

Track progress for each constant category:

- [ ] Debug configuration (5 constants)
- [ ] Hotspot configuration (3 constants)
- [ ] Viewer configuration (1 constant)
- [ ] Teaser system (11 constants across modules)
- [ ] Image processing (2 constants)
- [ ] Progress bar (1 constant)
- [ ] Notification system (2 constants)
- [ ] Download system (1 constant)
- [ ] FFmpeg configuration (3 constants)
- [ ] Project management (2 constants)
- [ ] Animation timing (6 constants)
- [ ] Scene organization (~50 constants across arrays)
- [ ] Backend configuration (1 constant)
- [ ] Navigation & simulation (6 constants)

**Total: ~90 constants to migrate**

---

## Dependencies

None - standalone refactor

---

## Rollback Plan

If issues arise:
1. Keep `constants.js` temporarily
2. Revert individual file imports one by one
3. When stable, retry migration

Alternative:
- Use both systems temporarily (gradual migration)

---

## Related Files

**New:**
- `src/utils/Constants.res` (create)

**Modified (estimated 20-30 files):**
- `src/systems/BackendApi.res`
- `src/systems/ExifParser.res`
- `src/systems/Navigation.res`
- `src/systems/TeaserRecorder.res`
- `src/systems/TeaserManager.res`
- `src/systems/VideoEncoder.res`
- `src/systems/SimulationSystem.res`
- `src/components/ViewerLoader.res`
- `src/components/VisualPipeline.res`
- ... (and others using constants)

**Deleted:**
- `src/constants.js`

---

## Success Metrics

- ✅ `src/constants.js` deleted
- ✅ `grep "@module.*constants.js" src/` returns 0 results
- ✅ All compilation passes
- ✅ All runtime tests pass
- ✅ No behavior changes observed
- ✅ Bundle size ≤ previous (improved tree-shaking)
