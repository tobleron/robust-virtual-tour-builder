# Task D018: Surgical Refactor COMPONENTS FRONTEND

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
**Directive:** Decompose & Flatten: Use guard clauses to reduce nesting and extract dense logic into private helper functions. 🏗️ ARCHITECTURAL TARGET: Split into exactly 2 cohesive modules to respect the Read Tax (avg 300 LOC/module).

- [ ] - **../../src/components/VisualPipelineLogic.res** (Metric: [Nesting: 4.80, Density: 0.06, Coupling: 0.05] | Drag: 5.88 | LOC: 384/300)


## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D018/verification.json` (files at `_dev-system/tmp/D018/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D018/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-split snapshot for `src/components/VisualPipelineLogic.res`
- `src/components/VisualPipelineLogic.res` (10 functions, fingerprint f0aa9b3813c2c2a0508d06ff20499e1f10e44ede557ed08b5c526588dc0c13b7)
    - handleDragStart — handleDragStart = (pipeline: t, e) => {
    - handleDragEnd — handleDragEnd = (pipeline: t, e) => {
    - handleDragOver — handleDragOver = e => {
    - handleDragEnter — handleDragEnter = e => {
    - handleDragLeave — handleDragLeave = e => {
    - handleDrop — handleDrop = (
    - createDropZone — createDropZone = (pipeline: t, index: int, ~getState, ~dispatch) => {
    - nodeSize — nodeSize = 22
    - styles — styles =
    - render — render = (pipeline: t, state: Types.state, ~getState, ~dispatch) => {
