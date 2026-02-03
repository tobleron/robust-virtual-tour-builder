# 🧪 TASK 1199: Comprehensive Playwright E2E Automation (Circuit Breaker)

**Objective**: Implement a rock-solid, exhaustive Playwright E2E suite that validates the entire tour creation lifecycle, from raw asset ingestion to production-ready export. This suite must serve as a "Circuit Breaker" to detect regressions in state transitions, asynchronous processing, and cross-system synchronization.

## 📋 Requirements & Coverage

### 1. Infrastructure Setup
- **Installation**: Add `@playwright/test` to `devDependencies`.
- **Configuration**: Create `playwright.config.ts` supporting Chromium, Firefox, and Webkit.
- **Environment**: Setup `test:e2e` scripts that launch the backend and frontend in a clean state.
- **Fixtures**: Include sample 360 JPGs and a known-good `.vt.zip` for consistent testing.

### 2. The Commercial Hot Path (E2E Scenarios)
- **Ingestion**:
    - [ ] **ZIP Import**: Upload a `.vt.zip`, verify all scenes load and metadata is preserved.
    - [ ] **Batch Processing**: Drag 5+ panoramas, verify the upload progress bar, and confirm they appear in the `SceneList`.
- **The Editor Cycle**:
    - [ ] **Hotspot Creation**: Alt+Click in viewer to spawn a hotspot.
    - [ ] **Linking**: Successfully link Scene A to Scene B and verify the "Return Link" is auto-generated.
    - [ ] **Property Sync**: Change a Scene Name in the Sidebar and verify it updates in the Viewer HUD and internal State.
- **The Navigation Engine (Meticulous)**:
    - [ ] **FSM Lifecycle**: Tap an arrow. Assert state flow: `Idle` -> `Preloading` -> `Transitioning` -> `Stabilizing` -> `Idle`.
    - [ ] **Camera Precision**: Verify camera `Yaw`/`Pitch` match the `journeyData` arrival targets after transition.
- **Autopilot & Simulation**:
    - [ ] **Journey Planning**: Trigger a 3-scene simulation and verify the viewer automatically navigates through them.
- **Persistence**:
    - [ ] **IndexedDB Shield**: Perform edits, reload page, and assert the state is identical (Hydration check).
- **Final Output**:
    - [ ] **Export Pipeline**: Trigger "Export Tour", verify ZIP generation, and check for `tour.json` presence.

### 3. Stability & Race Condition Stress-Testing
- **Stress-Transition**: Click a navigation arrow, then immediately click a different scene in the Sidebar while `Transitioning`. Assert FSM recovery.
- **Viewer Recycling**: Rapidly switch between 20 scenes and verify no `WebGL` context loss or memory leaks.

## 🛠️ Implementation Steps
1. **Scaffold**: Install dependencies and initialize Playwright config.
2. **Setup Fixtures**: Create a `tests/e2e/fixtures` directory with minimal test assets.
3. **Core Test Implementations**: 
    - `ingestion.spec.ts`
    - `navigation.spec.ts`
    - `editor.spec.ts`
4. **CI Integration**: Ensure tests can run headlessly with `npm run test:e2e:headless`.

## ✅ Success Criteria
- `npm run test:e2e` passes with zero flakiness (5/5 runs).
- Every "Hang" scenario identified in Feb 2026 is covered by a regression test.
- All UI components are verified for "Premium Aesthetics" (no flickering during transitions).
