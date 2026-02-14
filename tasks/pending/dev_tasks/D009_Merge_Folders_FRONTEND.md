# Task D009: Merge Folders FRONTEND

## Objective
## 🧩 Merge Objective
**Role:** Architecture Cleanup Bot
**Goal:** Reduce File Fragmentation (Read Tax).
**Constraint:** Combined file must not exceed 800 LOC.
**Optimal State:** Related small modules are unified into a single context window, reducing token consumption.

## Tasks

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `Loader.rs`). CRITICAL: Delete the now-empty `src/systems/Scene/Loader/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `src/systems/Scene/Loader` (Metric: Recursive Feature Pod: 3 files in subtree sum to 157 LOC (fits in context). Max Drag: 7.30)
    - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderConfig.res`
    - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderEvents.res`
    - `src/systems/Scene/Loader/../../src/systems/Scene/Loader/SceneLoaderReuse.res`

### 🔧 Action: Merge Fragmented Folders
**Directive:** Unified Context: Consolidate these fragmented files into a single cohesive module file (e.g., `Project.rs`). CRITICAL: Delete the now-empty `src/systems/Project/` folder to reduce directory nesting tax and strip any existing '@efficiency' tags.

- [ ] Folder: `src/systems/Project` (Metric: Recursive Feature Pod: 3 files in subtree sum to 223 LOC (fits in context). Max Drag: 7.87)
    - `src/systems/Project/../../src/systems/Project/ProjectLoader.res`
    - `src/systems/Project/../../src/systems/Project/ProjectSaver.res`
    - `src/systems/Project/../../src/systems/Project/ProjectValidator.res`

## 🔎 Programmatic Verification
Baseline artifacts: `_dev-system/tmp/D009/verification.json` (files at `_dev-system/tmp/D009/files/`).
Run `cargo run --manifest-path _dev-system/analyzer/Cargo.toml --bin spec_diff -- --baseline _dev-system/tmp/D009/verification.json --targets <refactored files>` once the refactor is ready to ensure the function surface matches the captured snapshots.

### Pre-merge snapshots for recursive cluster `src/systems/Project`
- `src/systems/Project/ProjectValidator.res` (2 functions, fingerprint ffb8b47d9fa96368ea312d8169dd5eaa1483015d1303878c72ff2a41db8f1d2d)
    - validationReportWrapperDecoder — let validationReportWrapperDecoder = JsonCombinators.Json.Decode.object(field => {
    - validateProjectStructure — let validateProjectStructure = (data: JSON.t): result<JSON.t, apiError> => {
- `src/systems/Project/ProjectSaver.res` (1 functions, fingerprint c42113cfd078e9ae6337cfc42f8b2eafb4e6f41cb00b16fb9261f47629dd3230)
    - createSavePackage — let createSavePackage = (state: state, ~signal=?, ~onProgress: option<onProgress>=?): Promise.t<
- `src/systems/Project/ProjectLoader.res` (2 functions, fingerprint 7bb47c70e88fecbb9936fbaa6c783733acc07b4ab8b3b0a360dd97d8289cc7cd)
    - processLoadedProjectData — let processLoadedProjectData = (
    - loadProjectZip — let loadProjectZip = (zipFile: File.t, ~onProgress: option<onProgress>=?) => {
### Pre-merge snapshots for recursive cluster `src/systems/Scene/Loader`
- `src/systems/Scene/Loader/SceneLoaderReuse.res` (1 functions, fingerprint d82b4f05f066c46c12afa9b4b0f92dde0d042b5f7870965b09bda5c82bcf7c81)
    - findReusableInstance — let findReusableInstance = (pathRequest: pathRequest, targetIdx: int): option<ViewerSystem.Adapter.t> => {
- `src/systems/Scene/Loader/SceneLoaderEvents.res` (4 functions, fingerprint 0522ec5cc5a313c9df2046fa17f18930e7862610a72fba6b1196b6eef969920c)
    - isStaleTask — let isStaleTask = (
    - castToDict — let castToDict: 'a => dict<string> = %raw("(x) => (typeof x === 'object' && x !== null) ? x : {}")
    - onSceneLoad — let onSceneLoad = (
    - onSceneError — let onSceneError = (
- `src/systems/Scene/Loader/SceneLoaderConfig.res` (5 functions, fingerprint d93e3bc007bec00c94aaf62232e9bf3cf65185510088b069d046c18cd8854d67)
    - getHotspots — let getHotspots = (scene: scene, ~state, ~dispatch) =>
    - makeSceneConfig — let makeSceneConfig = (scene: scene, ~state, ~dispatch) => {
    - makeInitialConfig — let makeInitialConfig = (scene: scene, ~state, ~dispatch) => {
    - blankPanorama — let blankPanorama = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="
    - backgroundViewerConfig — let backgroundViewerConfig = () => {
