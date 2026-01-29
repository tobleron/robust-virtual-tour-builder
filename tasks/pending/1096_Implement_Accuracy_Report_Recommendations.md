# Task 1096: Implement Accuracy Report Recommendations

## Objective
Finalize the architectural improvements identified during the `_dev-system` accuracy audit. This task coordinates the execution of valid refactors and merges while acknowledging the refined metrics.

## Background
Following the merge of the `analysis-dev-system-accuracy` branch, the system has been tuned to avoid false positives. This task focuses on the remaining high-signal recommendations.

## Tasks

### 1. 🏗️ Structural & Merge Tasks
- [ ] **Consolidate Auth Service**: Merge `backend/src/services/auth/jwt.rs` into `mod.rs` to reduce fragmentation. (Reference Task 1093)
- [ ] **CSS Fragmentation Audit**: Review `./css/components/` and consider merging small files into logical groups (e.g., `navigation.css`, `ui-elements.css`).
- [ ] **Fix Ambiguity**: Classify `src/index.js` in `MAP.md` or add `@efficiency-role`.

### 2. ⚡ Surgical Refactors (High Priority)
- [ ] **Navigation System**: Split `src/systems/Navigation.res` into `NavigationFSM.res` and `NavigationRenderer.res`.
- [ ] **Pathfinder Logic**: Extract core algorithm from `backend/src/pathfinder.rs` into specialized helper modules.
- [ ] **Viewer Style**: Partition `css/components/viewer.css` to reduce monolithic complexity.

### 3. ✅ Verification
- [ ] Run `npm run test` and `cargo test`.
- [ ] Execute `_dev-system` analyzer and verify Drag scores are within target limits (< 2.0).
