# T1791 Troubleshoot: Chromium Viewer Loading Timeout

## Objective
Fix Chromium-specific viewer loading timeout that prevents scene transitions in both manual navigation and simulation mode.

## Background

This issue was discovered during T1790 (Tour Preview Simulation Unreliability) investigation. The simulation logic was fixed and works correctly in Firefox, but Chromium fails to load scenes due to viewer timeout.

## Problem Description

### Symptoms
- Scene transitions fail in Chromium with timeout errors
- Both manual navigation (hotspot clicks) and simulation mode affected
- Error: `Timeout waiting for viewer to load scene`
- Warning: `NO_INACTIVE_VIEWER_FOR_SWAP`

### Browser Comparison

| Browser | Manual Navigation | Simulation Mode |
|---------|------------------|-----------------|
| Firefox | ✅ Works | ✅ Works |
| Chromium | ❌ Fails | ❌ Fails |

### Console Error Logs (Chromium)

```
[warning] SCENE_LOAD_RETRY {scene: 001_Zoom_Out_View.webp, attempt: 2, error: Timeout waiting for viewer...}
[warning] SCENE_LOAD_RETRY {scene: 001_Zoom_Out_View.webp, attempt: 3, error: Timeout waiting for viewer...}
[warning] NO_INACTIVE_VIEWER_FOR_SWAP
```

## Hypothesis (Ordered by Probability)

### 1. ViewerPool Initialization Issue (HIGHEST PROBABILITY)
**Expected Fix**: Fix ViewerPool initialization sequence in Chromium

**Problem**:
- `ViewerSystem.Pool` may not be properly initializing two viewer instances in Chromium
- `getInactiveViewer()` returns `None`, causing swap to fail
- WebGL context creation may differ between browsers

**Investigation Path**:
- Check `ViewerSystem.Pool` initialization in `src/systems/ViewerSystem/ViewerPool.res`
- Verify both `primary-a` and `primary-b` containers are created
- Check WebGL context creation in Chromium

### 2. Scene Texture Loading Timeout (HIGH PROBABILITY)
**Expected Fix**: Increase timeout or fix texture loading in Chromium

**Problem**:
- `pollForViewer` times out after waiting for viewer with correct scene ID
- Scene texture may be loading slower in Chromium
- Default timeout may be too aggressive for Chromium

**Investigation Path**:
- Check `Constants.sceneLoadTimeout` value
- Monitor scene loading progress in Chromium dev tools
- Compare texture loading times between Firefox and Chromium

### 3. WebGL Context/Renderer Differences (MEDIUM PROBABILITY)
**Expected Fix**: Add Chromium-specific WebGL workarounds

**Problem**:
- Chromium may have different WebGL capabilities or limitations
- GPU stall warnings observed: `GPU stall due to ReadPixels`
- Pannellum may not be initializing correctly in Chromium

**Investigation Path**:
- Check WebGL capabilities in both browsers
- Review Pannellum initialization options
- Look for Chromium-specific WebGL issues

### 4. DOM Container Availability (MEDIUM PROBABILITY)
**Expected Fix**: Ensure viewer containers are ready before initialization

**Problem**:
- DOM containers (`#primary-a`, `#primary-b`) may not be ready
- Race condition between DOM ready and viewer initialization
- Chromium may have different DOM ready timing

**Investigation Path**:
- Check container existence before viewer creation
- Add explicit DOM ready waits
- Verify container dimensions are valid

### 5. Service Worker / Cache Issue (LOWER PROBABILITY)
**Expected Fix**: Clear cache or adjust service worker behavior

**Problem**:
- Service worker may be caching differently in Chromium
- Scene images may not be loading from cache correctly
- Different cache behavior between browsers

**Investigation Path**:
- Test with service worker disabled
- Check network tab for scene image loading
- Compare cache behavior between browsers

## Activity Log

- [ ] Read and analyze ViewerSystem.Pool implementation
- [ ] Read and analyze ViewerSystem.Pool initialization
- [ ] Check sceneLoadTimeout constant value
- [ ] Test manual navigation in Chromium with dev tools open
- [ ] Compare WebGL capabilities between Firefox and Chromium
- [ ] Create fix based on root cause
- [ ] Verify fix with Playwright test (t1790-second-scene-animation.spec.ts)
- [ ] Run full navigation test suite in Chromium

## Code Change Ledger

| File | Change | Revert Note |
|------|--------|-------------|
| (pending) | (pending) | (pending) |

## Rollback Check
- [x] Confirmed CLEAN (no changes made yet)

## Context Handoff

**Summary**: Chromium browser fails to load scenes in the virtual tour viewer, causing timeouts in both manual navigation and simulation mode. The issue is in the viewer system (`ViewerSystem.Pool`), not the simulation logic. Firefox works correctly, indicating the code is fundamentally sound but has browser-specific compatibility issues.

**Key Files to Investigate**:
- `src/systems/ViewerSystem/ViewerPool.res` - Viewer pool management
- `src/systems/ViewerSystem.res` - Main viewer system
- `src/systems/Scene/SceneTransition.res` - Scene swap logic
- `src/systems/Simulation/SimulationNavigation.res` - waitForViewerScene function
- `src/utils/Constants.res` - Timeout constants

**Related Issues**:
- T1790: Tour preview simulation unreliability (root cause was this viewer loading issue)
- Basic navigation test fails: `navigation.spec.ts` - "should navigate between scenes via hotspot"

**Diagnostic Tools**:
- Playwright test: `tests/e2e/t1790-second-scene-animation.spec.ts`
- Console logs: Filter for `SIM_`, `Viewer`, `SceneTransition`
- Network tab: Monitor scene image loading
- WebGL tab: Check GPU capabilities and errors

## Diagnostic Commands

```bash
# Run T1790 test to verify viewer loading
npx playwright test t1790-second-scene-animation.spec.ts --project=chromium

# Run basic navigation test
npx playwright test navigation.spec.ts --project=chromium --grep "should navigate"

# Run all Chromium tests
npx playwright test --project=chromium

# View test results
npx playwright show-report
```

## Expected Fix Impact

Once fixed, the following will work in Chromium:
- ✅ Manual scene navigation via hotspots
- ✅ Tour preview simulation mode
- ✅ Auto-forward chains
- ✅ Teaser generation
- ✅ All E2E tests pass in Chromium

## Test Verification

After fix, run:
```bash
# Should pass in Chromium
npx playwright test t1790-second-scene-animation.spec.ts --project=chromium
npx playwright test navigation.spec.ts --project=chromium
npx playwright test simulation-teaser.spec.ts --project=chromium
```

All tests should show:
- Scenes visited: Multiple scenes (not just [0])
- Visited LinkIds: Non-empty array
- Timeline changes: Multiple changes
- No timeout errors
