# Task 1303: Viewer System E2E Issues Investigation (AGGREGATED)

**Status**: Pending Investigation
**Priority**: High - Blocks editor functionality and panorama loading
**Depends On**: Task 1296 (rate limiter fix - now complete ✅)

## 📋 Overview

This task aggregates two related viewer/Pannellum issues discovered during E2E testing:

1. **Editor Viewer Initialization Timeout** (Task 1281)
2. **Pannellum FileReader Blob Error** (Task 1302)

Both issues affect the core panorama viewer system and need investigation together as they may be related.

---

## Issue #1: Editor Viewer Initialization Timeout

### Objective
Restore reliability of the 360 viewer component in the Editor by resolving initialization timeout found during E2E testing.

### Failure Details
- **Test File**: `tests/e2e/editor.spec.ts`
- **Failure Point**: Line 58 - waiting for `#viewer-stage` element
- **Error**: `locator.waitFor: Timeout 30000ms exceeded.`
- **Impact**: Blocks ALL editor functionality tests
- **Timeline**: Viewer takes >30s to appear (or doesn't appear at all)

### Root Cause Hypotheses
1. **Race condition in mounting**: ViewerUI or ViewerManager initialization timing
2. **Missing DOM element**: `#viewer-stage` never created or ID mismatch
3. **Pannellum initialization failure**: JS errors during panorama library init
4. **State machine deadlock**: TransitionLock stuck or FSM in invalid state

### Investigation Checklist
- [ ] Run E2E test with `--debug` flag to capture browser console
- [ ] Check for JS errors during test execution
- [ ] Verify `#viewer-stage` element is created in DOM
- [ ] Inspect ViewerUI.res and ViewerManager.res initialization
- [ ] Check if Pannellum library is loaded correctly
- [ ] Verify Pannellum is receiving valid scene/image data
- [ ] Check TransitionLock state during initialization

### Key Files to Investigate
- `src/components/ViewerUI.res` - Viewer component rendering
- `src/systems/ViewerManager.res` - Viewer lifecycle management
- `src/systems/ViewerPool.res` - Dual-instance pool management
- `tests/e2e/editor.spec.ts` - Test reproduction harness

---

## Issue #2: Pannellum FileReader Blob Exception

### Objective
Investigate and fix FileReader exception occurring during rapid navigation and error recovery scenarios.

### Failure Details
- **Error**: `TypeError: Failed to execute 'readAsBinaryString' on 'FileReader': parameter 1 is not of type 'Blob'.`
- **Location**: `pannellum.js:1247:38`
- **Symptom**: Panorama viewer may fail to load images during rapid scene switching
- **Frequency**: Frequent during robustness and error recovery tests
- **Context**: Occurs during `loadNewScene` calls

### Root Cause Hypotheses
1. **Invalid blob passed to Pannellum**: Null or undefined image data
2. **Scene data corruption**: Malformed scene object structure
3. **Race condition**: Image loading completes after scene switch
4. **Error recovery issue**: Blob not properly reset after failed load attempt
5. **CORS/Network error**: NS_ERROR_NET_RESET related to failed fetch

### Investigation Checklist
- [ ] Review SceneLoader.res image loading logic
- [ ] Check SceneSwitcher.res scene data passing
- [ ] Verify blob data structure before passing to Pannellum
- [ ] Check for null/undefined checks in image data pipeline
- [ ] Investigate error recovery path for network failures
- [ ] Trace blob lifecycle through scene load → swap → cleanup
- [ ] Check if issue reproduces with network throttling enabled

### Key Files to Investigate
- `src/systems/Scene/SceneLoader.res` - Scene/image loading logic
- `src/systems/Scene/SceneSwitcher.res` - Scene switching implementation
- `src/systems/ViewerPool.res` - Image blob management
- `src/bindings/Pannellum.res` - Pannellum JS bindings
- Backend image processing: `backend/src/services/media/` - Image pipeline

---

## Related Completed Tasks

- **Task 1296** ✅: Rate limiting fixed (was blocking page initialization)
- **Task 1297** ✅: Notification system restored
- **Task 1298** ✅: Accessibility improvements

These fixes may have already resolved some of the viewer initialization issues.

---

## Investigation Steps

### Phase 1: Reproduce Issue #1
1. Start services (npm run dev)
2. Run E2E test: `npx playwright test tests/e2e/editor.spec.ts --debug`
3. Observe browser console for errors
4. Check if `#viewer-stage` exists in DOM
5. Take screenshot of viewer area (or lack thereof)
6. Document timeline: page load → viewer init → #viewer-stage appears

### Phase 2: Investigate Issue #2
1. Look for FileReader exception in test logs
2. Identify which scene load triggered the error
3. Check network tab for image fetch failures
4. Trace blob handling in SceneLoader
5. Verify error recovery doesn't pass invalid blobs

### Phase 3: Check for Dependencies
1. Do issues occur together or separately?
2. Is Issue #2 a symptom of Issue #1 (viewer not initialized)?
3. Is CORS/network failure causing blob errors?
4. Does rate limit fix (1296) resolve either issue?

### Phase 4: Fix & Verify
1. Apply minimal fix to unblock viewer initialization
2. Re-run E2E editor tests
3. Monitor for FileReader exceptions
4. Verify panorama loads correctly
5. Test rapid scene switching
6. Verify error recovery path

---

## Success Criteria

- [ ] `tests/e2e/editor.spec.ts` passes (viewer initializes in <2s)
- [ ] `#viewer-stage` appears in DOM within 2 seconds
- [ ] No FileReader blob exceptions in console
- [ ] Panorama images load correctly during scene transitions
- [ ] Rapid scene clicking doesn't trigger errors
- [ ] Error recovery doesn't create invalid blobs
- [ ] No regressions in navigation tests
- [ ] Performance acceptable (<5s per scene load)

---

## Debugging Guide

### If Viewer Still Times Out (After Rate Limit Fix)

**Check 1: Is Pannellum Library Loaded?**
```bash
grep -r "pannellum" src/components/ | grep -E "(import|external)"
```

**Check 2: Is #viewer-stage Created?**
```javascript
// In browser console during test
document.querySelector('#viewer-stage') // Should exist
```

**Check 3: Are There JS Errors?**
```bash
# Look for viewport initialization errors in test traces
npx playwright test tests/e2e/editor.spec.ts --trace on
# Then open trace in Playwright Inspector
```

**Check 4: Is ViewerUI Rendering?**
```rescript
// In ViewerUI.res - add Logger.info at component entry
Logger.info(~module_="ViewerUI", ~message="RENDERING", ())
```

### If FileReader Blob Error Occurs

**Check 1: Trace Blob Source**
```bash
grep -r "readAsBinaryString\|Blob\|image/jpeg" src/systems/Scene/
```

**Check 2: Verify Scene Data**
```bash
# Add logging to SceneLoader before Pannellum call
Logger.info(~module_="SceneLoader", ~message="SCENE_DATA",
  ~data=Some({
    "hasImage": image != null,
    "blobType": typeof image,
  }), ())
```

**Check 3: Check Network Errors**
```javascript
// Monitor fetch failures in browser console
window.addEventListener('unhandledrejection', e => console.log("FETCH ERROR:", e))
```

---

## Task Completion Instructions

### When Both Issues Fixed
1. Update this task with verification results
2. Mark as DONE with postfix `_RESOLVED`
3. Create new task for any regressions found
4. Archive old tasks 1281 & 1302 as superseded

### If Partial Progress
1. Update issue status and findings
2. Create focused sub-tasks for remaining issues
3. Keep this task in active status

### If Blocked
1. Document blocking factors
2. Create dependency task (e.g., "Fix ViewerManager initialization")
3. Update this task with new blockers list
