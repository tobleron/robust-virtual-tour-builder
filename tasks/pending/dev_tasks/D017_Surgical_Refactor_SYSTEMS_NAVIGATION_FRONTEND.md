# Task D017: Surgical Refactor SYSTEMS NAVIGATION FRONTEND

## Objective
## ⚡ Surgical Objective
**Role:** Senior Refactoring Engineer
**Goal:** De-bloat module to < 1.80 Drag Score.
**Strategy:** Extract highlighted 'Hotspots' into sub-modules.
**Optimal State:** The file becomes a pure 'Orchestrator' or 'Service', with complex math/logic moved to specialized siblings.

### 🎯 Targets (Focus Area)
The Semantic Engine has identified the following specific symbols for refactoring:

## Tasks

### 🔧 Action: De-bloat
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions.

- [ ] - **../../src/systems/Navigation/NavigationController.res** (Metric: [Nesting: 4.20, Density: 0.10, Coupling: 0.09] | Drag: 5.30 | LOC: 293/300  ⚠️ Trigger: Drag above target (1.80) with file already at 293 LOC.  🎯 Target: Function: `taskInfo` (High Local Complexity (18.2). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/systems/Navigation/NavigationRenderer.res** (Metric: [Nesting: 4.20, Density: 0.03, Coupling: 0.08] | Drag: 5.32 | LOC: 266/300  ⚠️ Trigger: Drag above target (1.80) with file already at 266 LOC.  🎯 Target: Function: `blinkStartTime` (High Local Complexity (7.0). Logic heavy.)) → Refactor in-place

- [ ] - **../../src/systems/Navigation/NavigationSupervisor.res** (Metric: [Nesting: 2.40, Density: 0.02, Coupling: 0.04] | Drag: 3.55 | LOC: 302/300  ⚠️ Trigger: Drag above target (1.80) with file already at 302 LOC.  🎯 Target: Function: `notifyListeners` (High Local Complexity (1.5). Logic heavy.)) → 🏗️ Split into 2 modules (target ~300 LOC each)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D017/verification.json` (files at `_dev-system/tmp/D017/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D017/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/systems/Navigation/NavigationController.res`
- `src/systems/Navigation/NavigationController.res` (3 functions, fingerprint 528a449b5f2d109fb3482bd702777033e982a494b530574cdfb44af64edb3483)
    - Grouped summary:
        - make × 1 (lines: 290)
        - useNavigationAnimation × 1 (lines: 161)
        - useNavigationFSM × 1 (lines: 9)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Navigation/NavigationRenderer.res`
- `src/systems/Navigation/NavigationRenderer.res` (5 functions, fingerprint cd2211a5b7d5f2c9884217bcc0768a64183f5321635aa27b1c1bae2cd85ab547)
    - Grouped summary:
        - activeJourneyId × 1 (lines: 13)
        - blinkStartTime × 1 (lines: 14)
        - loop × 1 (lines: 17)
        - setupBlinks × 1 (lines: 6)
        - startLoop × 1 (lines: 267)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
### Pre-split snapshot for `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/Navigation/NavigationSupervisor.res` (24 functions, fingerprint 969967f99517e2335147aa27c73a1222db1d0461125f6743e62ff8f738d7f62f)
    - Grouped summary:
        - abort × 1 (lines: 321)
        - addStatusListener × 1 (lines: 60)
        - complete × 1 (lines: 289)
        - configure × 1 (lines: 120)
        - currentTask × 1 (lines: 33)
        - dispatchInternal × 1 (lines: 124)
        - dispatchRef × 1 (lines: 118)
        - getCurrentTask × 1 (lines: 80)
        - getRunId × 1 (lines: 84)
        - getStatus × 1 (lines: 76)
        - isBusy × 1 (lines: 72)
        - isCurrentTaskId × 1 (lines: 95)
        - isCurrentToken × 1 (lines: 88)
        - isIdle × 1 (lines: 68)
        - listeners × 1 (lines: 35)
        - notifyListeners × 1 (lines: 43)
        - requestNavigation × 1 (lines: 157)
        - reset × 1 (lines: 102)
        - resetInFlightJourneyState × 1 (lines: 131)
        - runId × 1 (lines: 36)
        - status × 1 (lines: 34)
        - statusToString × 1 (lines: 147)
        - taskCounter × 1 (lines: 32)
        - transitionTo × 1 (lines: 237)
    - Detailed entries are preserved in baseline JSON (`verification.json`) for machine-level diffs.
