# Task 1069: Classify Ambiguous Files with Efficiency Headers

## Objective
Analyze the 111 files listed as "Ambiguous" in `_dev-system/pending/SYSTEM_PLAN.md` and insert the appropriate `@efficiency` header to classify their architectural role. This will enable the AI-Native math engine to apply correct LOC limits and Drag calculations.

## Context
The `_dev-system` uses a taxonomy-based governor. Files without a classification default to "unknown" and bypass governance. We need to "stamp" these files with their true intent.

## Instructions
1.  **Read the Ambiguity List**: Open `_dev-system/pending/SYSTEM_PLAN.md` and locate the "PRECURSOR: AMBIGUITY RESOLUTION" section.
2.  **Analyze Content**: For each file, determine its role based on the logic:
    -   `orchestrator`: Main entry points, complex coordination logic.
    -   `ui-component`: React/Pannellum UI elements, styles, templates.
    -   `service-orchestrator`: Systems, Managers, complex Logic modules.
    -   `domain-logic`: Pure business rules, core state transitions.
    -   `state-reducer`: Redux-style reducers and state handlers.
    -   `data-model`: Types, Schemas, Struct definitions.
    -   `infra-adapter`: API clients, DB connectors, hardware/browser bindings.
    -   `util-pure`: Math helpers, string utils, pure functional helpers.
    -   `infra-config`: Configuration files, scripts, build tools.
3.  **Insert Header**: Add the header at the top of the file using the correct comment style:
    -   **ReScript/Rust/JS/JSX**: `// @efficiency: [role]`
    -   **CSS**: `/* @efficiency: [role] */`
    -   **HTML**: `<!-- @efficiency: [role] -->`
    -   **JSON**: `"@efficiency": "[role]"` (As a top-level property).
    -   **YAML/TOML**: `# @efficiency: [role]`
4.  **Verify**: Re-run the analyzer (`cd _dev-system/analyzer && cargo run --release`) to ensure the "Ambiguity" count drops to 0.

## Success Criteria
-   Zero files listed under "Ambiguity" in the next scan.
-   All source files have correctly assigned roles.
- [x] `../../tests/unit/Logger_v.test.res`
- [x] `../../tests/unit/Sidebar_v.test.res`
- [x] `../../tests/unit/LazyLoad_v.test.res`
- [x] `../../tests/unit/NavigationFSM_v.test.res`
- [x] `../../tests/unit/ProjectionMath_v.test.res`
- [x] `../../tests/unit/EventBus_v.test.res`
- [x] `../../tests/unit/VideoEncoder_v.test.res`
- [x] `../../tests/unit/Components_v.test.setup.jsx`
- [x] `../../tests/unit/SceneCache_v.test.res`
- [x] `../../tests/unit/HotspotLayer_v.test.res`
- [x] `../../tests/unit/HotspotLine_v.test.res`
- [x] `../../tests/unit/VitestSmoke.test.res`
- [x] `../../tests/unit/Mod_v.test.res`
- [x] `../../tests/unit/App_v.test.res`
- [x] `../../tests/unit/FloorNavigation_v.test.res`
- [x] `../../tests/unit/FinalAsyncCheck_v.test.res`
- [x] `../../tests/unit/PanoramaClusterer_v.test.res`
- [x] `../../tests/unit/UploadReport_v.test.res`
- [x] `../../tests/unit/SceneLoader_v.test.res`
- [x] `../../tests/unit/UploadProcessor_v.test.res`
- [x] `../../tests/unit/SimulationDriver_v.test.res`
- [x] `../../tests/unit/ServerTeaser_v.test.res`
- [x] `../../tests/unit/LoggerTelemetry_v.test.res`
- [x] `../../tests/unit/SimulationChainSkipper_v.test.res`
- [x] `../../tests/unit/SceneList_v.test.res`
- [x] `../../tests/unit/NotificationLayer_v.test.res`
- [x] `../../tests/unit/ReturnPrompt_v.test.res`
- [x] `../../tests/unit/QualityIndicator_v.test.res`
- [x] `../../tests/unit/PannellumLifecycle_v.test.res`
- [x] `../../tests/unit/NavigationUI_v.test.res`
- [x] `../../tests/unit/HotspotMenuLayer_v.test.res`
- [x] `../../tests/unit/TourTemplateAssets_v.test.res`
- [x] `../../tests/unit/Constants_v.test.res`
- [x] `../../tests/unit/SceneSwitcher_v.test.res`
- [x] `../../tests/unit/ProgressBar_v.test.res`
- [x] `../../tests/unit/TourTemplateStyles_v.test.res`
- [x] `../../tests/unit/LabelMenu_v.test.setup.jsx`
- [x] `../../tests/unit/SessionStore_v.test.res`
- [x] `../../tests/unit/ProjectData_v.test.res`
- [x] `../../tests/unit/TeaserPlayback_v.test.res`
- [x] `../../tests/unit/HotspotActionMenu_v.test.res`
- [x] `../../tests/unit/Resizer_v.test.res`
- [x] `../../tests/unit/TourTemplates_v.test.res`
- [x] `../../tests/unit/LinkModal_v.test.res`
- [x] `../../tests/unit/VisualPipeline_v.test.res`
- [x] `../../tests/unit/LucideIcons_v.test.res`
- [x] `../../tests/unit/PersistentLabel_v.test.res`
- [x] `../../tests/unit/ErrorFallbackUI_v.test.res`
- [x] `../../tests/unit/SceneLoader_Lifecycle_Unified_v.test.res`
- [x] `../../tests/unit/Portal_v.test.res`
- [x] `../../tests/unit/UploadProcessor_v.test.setup.js`
- [x] `../../tests/unit/Version_v.test.res`
- [x] `../../tests/unit/NavigationGraph_v.test.res`
- [x] `../../tests/unit/TourTemplateScripts_v.test.res`
- [x] `../../tests/unit/PathInterpolation_v.test.res`
- [x] `../../tests/unit/NavigationRenderer_v.test.res`
- [x] `../../tests/unit/TeaserPathfinder_v.test.res`
- [x] `../../tests/unit/DownloadSystem_v.test.res`
- [x] `../../tests/unit/Main_v.test.res`
- [x] `../../tests/unit/ExifReportGenerator_v.test.res`
- [x] `../../tests/unit/SvgRenderer_v.test.res`
- [x] `../../tests/unit/RequestQueue_v.test.res`
- [x] `../../tests/unit/UtilityBar_v.test.res`
- [x] `../../tests/unit/ImageValidator_v.test.res`
- [x] `../../tests/unit/ImageOptimizer_v.test.res`
- [x] `../../tests/unit/NavigationController_v.test.res`
- [x] `../../tests/unit/SnapshotOverlay_v.test.res`
- [x] `../../tests/unit/ExifParser_v.test.res`
- [x] `../../tests/unit/PannellumAdapter_v.test.res`
- [x] `../../tests/unit/LabelMenu_v.test.res`
- [x] `../../tests/unit/PopOver_v.test.res`
- [x] `../../tests/unit/ColorPalette_v.test.res`
- [x] `../../tests/unit/HotspotLine_v.test.setup.js`
- [x] `../../tests/unit/TeaserRecorder_v.test.res`
- [x] `../../tests/unit/Exporter_v.test.res`
- [x] `../../tests/unit/FingerprintService_v.test.res`
- [x] `../../tests/unit/SimulationNavigation_v.test.res`
- [x] `../../tests/unit/AppErrorBoundary_v.test.res`
- [x] `../../tests/unit/Shadcn_v.test.res`
- [x] `../../tests/unit/InputSystem_v.test.res`
- [x] `../../tests/unit/CursorPhysics_v.test.res`
- [x] `../../tests/unit/SimulationPathGenerator_v.test.res`
- [x] `../../tests/unit/VersionData_v.test.res`
- [x] `../../tests/unit/Tooltip_v.test.res`
- [x] `../../tests/rescript-schema-shim.js`
- [x] `../../tests/TestRunner.res`
- [x] `../../tests/node-setup.js`
- [x] `../../backend/tests/shutdown_test.rs`
- [x] `../../backend/src/middleware/request_tracker.rs`
- [x] `../../backend/src/middleware/quota_check.rs`
- [x] `../../backend/src/middleware/auth.rs`
- [x] `../../backend/src/pathfinder/graph.rs`
- [x] `../../backend/src/pathfinder/algorithms.rs`
- [x] `../../backend/src/metrics.rs`
- [x] `../../backend/src/services/shutdown.rs`
- [x] `../../backend/src/services/database.rs`
- [x] `../../backend/src/services/auth/jwt.rs`
- [x] `../../backend/src/services/upload_quota.rs`
- [x] `../../backend/src/services/project/package.rs`
- [x] `../../backend/src/services/project/load.rs`
- [x] `../../backend/src/services/project/validate.rs`
- [x] `../../backend/src/services/upload_quota_tests.rs`
- [x] `../../backend/src/services/media/resizing.rs`
- [x] `../../backend/src/services/media/analysis/quality.rs`
- [x] `../../backend/src/services/media/analysis/exif.rs`
- [x] `../../backend/src/services/media/naming.rs`
- [x] `../../backend/src/services/media/webp.rs`
- [x] `../../backend/src/services/media/naming_old.rs`
- [x] `../../backend/src/services/media/storage.rs`
- [x] `../../rescript.json`
- [x] `../../.vscode/settings.json`
- [x] `../../src/i18n/locales/en.json`
- [x] `../../src/i18n/locales/es.json`
- [x] `../../src/i18n/I18n.res`
