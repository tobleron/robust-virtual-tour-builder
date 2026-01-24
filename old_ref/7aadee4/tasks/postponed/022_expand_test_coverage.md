# Task 22: Hardening Core Systems (Regression Shield)

## 🎯 Objective
Establish a rigorous "Regression Shield" around the stable core systems of the application. The goal is to ensure that adding future features does not break existing fundamental logic (State Management, Navigation, Data Integrity).

**Note:** Exporter and Teaser systems are currently excluded as they are still under active development.

## 🛡️ Scope & Implementation

### 1. State Management (The Brain)
**Target:** `src/core/reducers/`
**Goal:** 100% Branch Coverage
**Why:** This is the highest risk area. A bug here corrupts the entire application state.

- [x] **SceneReducer**:
    - Test every action type (Add, Remove, Update, Reorder).
    - Test edge cases: Deleting the active scene, reordering invalid indices.
- [x] **HotspotReducer**:
    - Test adding/removing hotspots.
    - Test updating properties (yaw, pitch, target).
    - **Crucial:** Test integrity (e.g., ensuring `linkId` is unique).
- [x] **NavigationReducer**:
    - Test history stack management (if applicable).
    - Test auto-forward chain logic.

### 2. Navigation System (The Engine)
**Target:** `src/systems/Navigation.res` (Logic only)
**Why:** Users *must* be able to move between scenes reliably.

- [x] **Pathfinding**:
    - Test `findSceneByName` with various naming conventions.
    - Test `getNextScene` / `getPreviousScene` in both linear and non-linear/filtered lists.
- [x] **Auto-Forward Logic**:
    - Test chain execution (does it stop at the right time?).
    - Test loop prevention (does it detect infinite auto-forward loops?).

### 3. Data Integrity (The Gatekeeper)
**Target:** `src/systems/ProjectManager.res` (Pure Logic functions only)
**Why:** Preventing corrupt data from entering the system is cheaper than fixing it later.

- [x] **Validation**:
    - Exhaustive testing of `validateProjectStructure`.
    - Create a suite of "Corrupt JSON" mock files (missing fields, wrong types) and ensure they are rejected with clear error messages.
    - Test "Version Migration" logic (if old project formats are supported).

## 🛠️ Technical Approach
- **Pure Logic First:** Focus on testing functions that take inputs and return outputs, avoiding DOM/Network mocks where possible.
- **Mock Data Factory:** Create a `TestUtils.res` module to generate valid/invalid `state` and `scene` objects quickly to reduce test boilerplate.

## 📊 Success Metrics
- **Zero Regressions:** Future refactors of these modules should immediately trigger test failures if behavior changes.
- **Coverage:** >90% coverage on `reducers/*` and `Navigation.res`.