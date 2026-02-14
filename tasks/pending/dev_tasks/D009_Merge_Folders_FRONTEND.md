# Task D009: Merge Folders FRONTEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `VisualPipeline.rs`). CRITICAL: Delete the now-empty `../../src/components/VisualPipeline/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `../../src/components/VisualPipeline` (Metric: Read Tax high (Score 2.00). Projected Limit: 300 (Drag 3.30))
    - `../../src/components/VisualPipeline/VisualPipelineComponent.res`
    - `../../src/components/VisualPipeline/VisualPipelineStyles.res`

## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009/verification.json` (files at `_dev-system/tmp/D009/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-merge snapshots for `../../src/components/VisualPipeline`
- `src/components/VisualPipeline/VisualPipelineStyles.res` (5 functions, fingerprint d1e5a4671f88d34fe9ad1530b0133db00980e46a1faca44b00c69f81269aa9af)
    - nodeSize — let nodeSize = 22
    - styles — let styles =
    - injectStyles — let injectStyles = () => {
    - existing — let existing = Dom.getElementById("visual-pipeline-styles")
    - style — let style = Dom.createElement("style")
- `src/components/VisualPipeline/VisualPipelineComponent.res` (8 functions, fingerprint 8889bc9bb4a75c8eb8356cd0aa22db80d22e02897a81c0fea3f02af216e3ac3c)
    - make — let make = () => {
    - containerRef — let containerRef = React.useRef(Nullable.null)
    - appState — let appState = AppContext.useAppState()
    - dispatch — let dispatch = AppContext.useAppDispatch()
    - stateRef — let stateRef = React.useRef(appState)
    - getState — let getState = () => stateRef.current
    - pipelineRef — let pipelineRef = React.useRef(None)
    - pipeline — let pipeline = VisualPipeline.initByElement(c)
