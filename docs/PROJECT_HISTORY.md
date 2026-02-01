# Project Evolution & Release History

This document tracks the iterative growth, version milestones, and long-term roadmap for the Robust Virtual Tour Builder.

---

## 🚀 Current Project Status
- **Version**: v4.3.7 (Stable UI)
- **Status**: Commercial Ready (Post-Gap Analysis)
- **ReScript Logic Coverage**: ~95%
- **Test Pass Rate**: 100% (40/40 Unit Tests)

---

## 📦 Version History

### v4.3.7: "Stable UI No Ghost" (2026-01-21)
- **Focus**: Final resolution of "Ghost Arrow" artifacts.
- **Key Changes**: Implemented "Iron Dome" CSS protections and loop de-confliction.

### v4.3.0: Commercial Compliance (2026-01-15)
- **Focus**: Legal and SEO readiness.
- **Key Changes**: Addition of Privacy Policy, Terms of Service, and structured data headers.

### v4.0.0: ReScript Transition (Early 2026)
- **Focus**: Migration from JavaScript to a type-safe functional architecture.
- **Key Changes**: Complete rewrite of the logic layer; introduction of the Rust backend.

---

## 🛠️ Notable Bug Fixes

### Fix: Project Name "Unknown" Bug (v2)
- **Robust Filtering**: Implemented optional type checking and case-insensitive regex (`/Unknown/i`) in `UploadProcessor.res` to reject dummy names.
- **Architecture Shift**: Updated `ExifReportGenerator.res` to return `option<string>` instead of "Unknown_Location" strings.
- **Diagnostics**: Added specific logs (`PROJECT_NAME_GENERATED_FROM_EXIF`, `SKIPPING_UNKNOWN_PROJECT_NAME`) for traceability.
- **Verification**: Updated unit tests to verify `None` return behavior.

---

## 🗺️ Strategic Roadmap

### Tier 1: Core Consolidation (COMPLETED)
- ✅ Centralized Reducer Architecture (ReScript).
- ✅ Rust-Powered Image Processing Pipeline.
- ✅ Robust State management via `RootReducer`.

### Tier 2: Refinement & Polish (CURRENT)
- 🏃 Final elimination of `Obj.magic` (38 remaining).
- 🏃 Migration of `Viewer.js` helper functions to ReScript.

### Tier 3: Advanced Intelligence (FUTURE)
- 🔮 AI-assisted scene categorization.
- 🔮 Deep image similarity for hotspot suggestions.
- 🔮 Interactive floor plan generation.

---

## 📊 Historical Reports Summary

### AutoPilot Simulation Analysis (2026-01-20)
- **Issue**: Timeout errors during simulation.
- **Fixes**: Unified timeout constants, enabled progressive loading during simulation, and added retry logic.

### Application Analysis (2026-01-25)
- **Status**: 9/10 Design System compliance, 9.5/10 Testing Health.
- **Findings**: `Obj.magic` usage regression (62 vs target 38).
- **Action**: Ongoing refactoring to reduce unsafe casting.

### E2E Performance Analysis
- **Status**: Framework setup complete (Playwright).
- **Challenges**: Backend image format detection in headless environment requires tuning.

---
*Last Updated: 2026-01-25*

---

## 🔬 System Analysis & Refinement Reports

### 📥 Analysis: _dev-system Accuracy (2026-02-01)
*Integrated from `docs/_pending_integration/ANALYSIS_DEV_SYSTEM_ACCURACY.md`*

The `_dev-system` structural analyzer was audited for accuracy across the stack.

**Findings:**
- **Backend (Rust)**: High accuracy (90%). Correctly identifies fragmentation/scope creep.
- **Frontend (ReScript)**: Low accuracy (10%). Penalizes standard ReScript patterns (switches/pattern matching) as "High Drag".

**Root Cause:**
- The "Complexity Density" formula unfairly weighted `switch` (0.8) and `|` (0.5) tokens, counting them both as density and complexity.
- Valid functional programming patterns were flagged as "Surgical Refactor" candidates (e.g., `HotspotManager.res` Drag 5.83).

**Corrective Actions:**
1. **Config Tuned**: `efficiency.json` updated for ReScript:
   - `->` (Pipe): Reduced 0.05 -> 0.0 (Syntactic sugar)
   - `switch`: Reduced 0.8 -> 0.2 (Essential control flow)
   - `| `: Reduced 0.5 -> 0.1 (Standard branching)
   - `mutable`: Increased 1.5 -> 2.0 (Discouraged)
   - `Obj.magic`: Increased 2.5 -> 5.0 (Dangerous)
2. **Strategy**: Backend tasks are greenlit; Frontend refactor tasks are paused until the formula stabilizes.

---

### 🧹 Refactoring Campaign: Tasks 1108, 1112-1114, 1116 (2026-02-01)
*Integrated from `docs/_pending_integration/analysis_1108_1114_1112_1113_1116.md`*

A major surgical refactoring campaign was executed to de-bloat core systems and improve modularity.

**1. Frontend Surgical Refactor (Task 1114)**
- **Objective**: De-bloat `src/systems/*.res`.
- **Action**: Extracted logic into `*Logic.res` counterparts.
  - `Api.res` -> `ApiLogic.res`
  - `ExifReportGenerator.res` -> `ExifReportGeneratorLogic.res`
  - `HotspotLine.res` -> `HotspotLineLogic.res`
  - `Simulation.res` -> `SimulationLogic.res`
  - `Teaser.res` -> `TeaserLogic.res`

**2. Backend Consolidation (Task 1112, 1113)**
- **Objective**: Reduce folder clutter and separate domains.
- **Action**:
  - **Merged**: `services/auth/` -> `auth.rs`, `services/geocoding/` -> `geocoding.rs`, `middleware/` -> `middleware.rs`.
  - **Extracted**: `pathfinder.rs` split into `pathfinder/` (graph, algorithms).

**3. Viewer CSS Cleanup (Task 1108)**
- **Objective**: Modularize monolithic CSS.
- **Action**: Split `viewer.css` into `viewer-hotspots.css` and `viewer-ui.css`.

**4. Map Classification (Task 1116)**
- **Objective**: 100% Map Coverage.
- **Action**: All unmapped modules classified in `MAP.md`.

**Verification**:
- ✅ Frontend Build `npm run build`: Pass.
- ✅ Backend Check `cargo check`: Pass.
