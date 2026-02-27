# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.12.5] - 2026-02-27

### Changed
- Workable stable telemetry+db tuning
- Wip: 1578 scene cache lru eviction
- 1578 lru cache hardening + tests
- 1579 eventbus weakref leak guard + 1580 clone offload
- Perf budget test hardening + 1578 latency validation
- Autosave main-thread cost instrumentation
- 1583 service worker cache list cleanup + regression test

## [4.12.5] - 2026-02-26

### Fixed
- Stabilize exported tour completion flow and glass panel shortcuts

### Changed
- Fix export map/auto-tour shortcuts and looking-mode defaults
- Refine export map transition and auto-tour home-return label suppression
- Stabilize export autotour home-return shortcut panel timing
- Fix export map exit row text truncation
- Usable Stable Version
- Workable Stable Version
- Working Stable Perfect Tour
- Add regression unit guards for export auto-forward landing
- Implement Fast Shots + Simple Crossfade teaser styles (workable stable version)

## [4.12.4] - 2026-02-26

### Fixed
- Toast overflow — CSS 2-line clamp + message shortening + truncateForToast safety net

## [4.12.3] - 2026-02-26

### Changed
- Refine Hotspot Move UX and Auto-Forward Toggle logic with regression tests
- Stable workable version
- --help
- Refine glass panel navigation shortcuts: Up/Down arrows and Map placeholder

## [4.12.3] - 2026-02-25

### Fixed
- Resolve hotspot waypoint failure after multiple moves by disabling visit optimization in builder

## [4.12.2] - 2026-02-25

### Fixed
- Resolve console errors and optimize log verbosity

### Changed
- Product spec, MAP/DATA_FLOW integration, 18 hardening tasks (P0-P3), D006/D009/D016 complete

## [4.12.0] - 2026-02-25

### Added
- Implement global animate-once policy and hub scene link visuals

### Changed
- Implement hub-scene return logic: 180-degree turn when returning to previous scene
- Exported tours: Auto-forward links expire after first use and become regular buttons
- Add regression tests for 180-degree return and session-based auto-forward expiration
- E2E: Add rotation regression test and script verification test

## [4.10.0] - 2026-02-25

### Added
- Improve teaser generation starting point and unify utility bar dimming

### Changed
- Hardened teaser generation: professional recording UI, interaction shield, logical locking, and regression tests.

## [4.9.0] - 2026-02-24

### Added
- Implement precise hotspot move mode decoupled from waypoints

## [4.8.6] - 2026-02-24

### Fixed
- Logo persistence through save/reload and inclusion in exported tours

## [4.8.0] - 2026-02-24

### Added
- Implement screenshot-style waypoint indicator (+) for short distances

### Changed
- Fix logo persistence and URL reconstruction in saved projects

## [4.5.4] - 2026-02-24

### Changed
- T1540: Fix floating progress spinner
- T1540: hide floating progress overlay

## [4.5.4] - 2026-02-23

### Fixed
- Harden linking state management and prevent stale view capture during transitions

### Changed
- Patch 4.5.5
- State normalization & teaser fixes
- Fix scene sequences and label numbering

## [4.5.3] - 2026-02-23

### Fixed
- Prevent stale view capture during scene transitions and auto-reset linking mode on navigation

## [4.5.2] - 2026-02-23

### Fixed
- Remove duplicate hotspot check and improve scene name display casing

## [4.5.1] - 2026-02-23

### Changed
- Deprecate triple-commit defaults and prune branch surface

### Fixed
- Link modal test failures and restore save logic

## [4.5.0] - 2026-02-23

### Changed
- Cross-operation ETA stability, cancel reset, and upload reliability hardening

## [4.30.23] - 2026-02-23

### Changed
- Ultra stable backend upload images
- Snapshot before autotune calibration and ETA notifications

## [4.30.23] - 2026-02-22

### Changed
- Test: update color palette tests to reflect restored 5-shade orange palette

## [4.30.21] - 2026-02-22

### Fixed
- Restore 5-shade orange color palette

## [4.30.19] - 2026-02-22

### Fixed
- Stabilize vitest suites & render visual pipeline immediately after linking mode

## [4.30.18] - 2026-02-22

### Changed
- Snapshot upload hardening and ongoing workspace changes

## [4.30.17] - 2026-02-22

### Changed
- Create task 1523 to fix vitest failures

## [4.30.16] - 2026-02-22

### Changed
- Sync teaser/export UX and processing polish

## [4.30.15] - 2026-02-22

### Changed
- Update color palette for visual pipeline and ensure home button displays on isolated floors
- Complete tasks 1517-1520: Deterministic cinematic teaser and backend scaffold
- Teaser/export lock and progress UX hardening

## [4.30.15] - 2026-02-21

### Changed
- Update MAP.md with new test and API modules
- V4.30.12+13 [TRIPLE]: fix post-simulation scene switch load abort by ignoring stale pannellum FileReader callbacks
- Set auto-forward hotspot and pipeline squares to emerald
- Teaser mp4-only capture-mode and progress lifecycle stabilization
- Teaser motion profile + real-time 60fps pacing
- Teaser capture smoothing + cdp migration task specification
- T1515: Move to active for Jules delegation

## [4.30.14] - 2026-02-21

### Fixed
- Stabilize utility bar and visual pipeline tests, add thumbnail generator and image optimizer unit tests, and harden scene item interactions

## [4.30.12] - 2026-02-21

### Changed
- Checkpoint: standardize thumbnail quality and pipeline preview behavior
- Remove temporary utility-bar trash button; align pipeline tooltip updates
- V4.30.12+export: redesign 3-mode exports (web_only/desktop/mobile), add export home shortcut, and compact glass panel
- V4.30.12+11 [TRIPLE]: builder viewport deprecation and visual pipeline spacing refinements

## [4.30.12] - 2026-02-20

### Changed
- Fix z-index for visual pipeline elements
- T1506 project-load stuck + cancel/esc hardening
- T1506 tooltip layer parity + 600ms pipeline hover + room-label preview dim
- T1506 restore thumbnail quality + reduce pipeline hover preview + clear-links prune timeline
- T1507 align e2e tooltip delay + add comprehensive e2e certification task

## [4.30.11] - 2026-02-20

### Changed
- Merge task-1502 visibility thresholds and align task 1503 lock-policy prerequisites
- T1503: Move to active for Jules delegation
- Review task-1503 branch (not merged) and strengthen task 1504 lock-policy interruptibility guardrails
- Task 1503 capability lock matrix + 1504 validation refresh
- T1504: Move to active for Jules delegation
- Task 1504 race reliability verification + certification e2e
- Tasks cleanup + D001 D003 D004 integration

## [4.30.10] - 2026-02-20

### Changed
- Merge task-1501 decoupling, validate behavior, and refine task 1502 prerequisites
- T1502: Move to active for Jules delegation

## [4.30.9] - 2026-02-20

### Changed
- Remove current file structure generation from commit workflows
- T1499: Completed; T1498: Moved to active for Jules delegation
- Add sequenced tasks 1501-1504 for navigation/progress/lock/race hardening
- T1501: Move to active for Jules delegation

## [4.30.8] - 2026-02-20

### Fixed
- Sanitize missing tinyFile refs and harden T1498 delegation spec

## [4.30.6] - 2026-02-20

### Fixed
- Visual pipeline active timing and define global operation progress orchestration task

### Changed
- T1495: Move to active for Jules delegation

## [4.30.4] - 2026-02-20

### Fixed
- Restore thumbnail queue progression beyond first scene

## [4.30.3] - 2026-02-20

### Fixed
- Restore thumbnail queue progression beyond first scene

## [4.31.0] - 2026-02-20

### Added
- **Tour Preview Enhancement**: Automatically navigate to the first scene (Scene 0) when starting a tour preview.
- **Cinematic Intro Pan**: Implemented smooth cinematic intro pan for the first scene of a tour preview by resetting the pan tracker on simulation start.

## [4.30.2] - 2026-02-20

### Changed
- Polish: fix intro pan on simulation start and auto-navigate to scene 0
- Refine Visual Pipeline tooltips: compact layout, orange border, navy footer, and removed Link ID

## [4.30.1] - 2026-02-20

### Changed
- Add artifacts/ to .gitignore, untrack large zips and logs, add storage check to commit workflow

## [4.30.0] - 2026-02-20

### Added
- Refactor visual pipeline to scalable floor-grouped squares with deterministic PCB-style lines

## [4.29.0] - 2026-02-19

### Added
- Implement enhanced network status tracking and rate-limit handling

## [4.27.0] - 2026-02-19

### Added
- Polish recovery/crash notification UX (task-1484, jules)

## [4.26.3] - 2026-02-19

### Changed
- Delegate task 1484 to jules and sync recent fixes to main/testing

## [4.26.2] - 2026-02-19

### Changed
- Merge: integrate jules-e2e-hardening improvements
- Fix sidebar operation cancellation: ESC key now aborts active Save/Export/Teaser, wired teaser onCancel, and cleaned up save cancellation UX

## [4.26.1] - 2026-02-19

### Fixed
- Vitest regressions and classify thumbnail modules (D001, D002)

## [4.26.0] - 2026-02-19

### Added
- Rectilinear thumbnail generation for all scenes (upload + project load)

## [4.25.0] - 2026-02-19

### Added
- Created `docs/VISUAL_PIPELINE_V1_REFERENCE.md` as a revert-safe design specification for the circle-chain pipeline.

### Changed
- **Visual Pipeline V2 Migration**: Replaced circle-chain design with a premium **thumbnail-chain** architecture.
- **Thumbnail Nodes**: Rectangular scene previews (44x30px) with 3px borders derived from scene histogram data.
- **Auto-Forward Indication**: Enhanced visibility by overriding the thumbnail border with **Indigo Pigment (#4B0082)** for scenes with auto-forward enabled.
- **Active State**: Refined active scene indicator with a **1px flush orange ring** (no gap) and scale-up animation.
- **Cleanup**: Removed drag-and-drop from the pipeline (moved to Sidebar DnD task T1483) and removed orange separator arrows for a cleaner look.
- **Performance**: Optimized thumbnail loading using `tinyFile` with fallback to main source.

## [4.24.0] - 2026-02-19

### Changed
- Migrate Visual Pipeline to V2 Thumbnail Chain and add design reference
- Fix syntax error in ThumbnailGenerator %raw block

## [4.23.0] - 2026-02-19

### Added
- Add visual indicator for shortcut selection and refine pre-push safety

## [4.22.0] - 2026-02-19

### Added
- Add visual indicator for shortcut selection in exported tours

## [4.21.0] - 2026-02-19

### Added
- Add visual indicator for shortcut selection in exported tours

## [4.19.2] - 2026-02-19

### Fixed
- Resolve telemetry & exporter test failures, stabilize network status, and sync latest refactors

## [4.19.1] - 2026-02-19

### Fixed
- Resolve telemetry & exporter test failures, stabilize network status simulation

## [4.19.0] - 2026-02-19

### Changed
- Ui: align utility bar and floor navigation in builder
- Fine-tune move cursor dynamics: frame-rate independent panning, vector smoothing, and smoothstep profile
- Portrait mode UX polish: hide looking mode & cursor, reposition room label tag to top-right, glass panel auto-sizes to fit-content for labels like MASTER BEDROOM
- T1479: Progress bar premium overhaul — phase-aware export progress, monotonic enforcement, message polish, shimmer animation
- Maintainance: Aggregate completed tasks (D002), classify map entries (D008), and integrate data-flow modules (D009)
- Architectural Batch 1: Fix Obj.magic in RequestQueue (D006) and consolidate Exporter modules (D011)
- Final Batch: Delegate remaining dev tasks to Jules (D001, D005, D007, D010)

## [4.19.0] - 2026-02-18

### Added
- Refine HUD typography shadows and logo branding

## [4.18.0] - 2026-02-18

### Added
- Remove screenshots and redesign HUD glass panel

## [4.17.0] - 2026-02-18

### Changed
- Surgical split of frontend systems (D001)

## [4.16.3] - 2026-02-18

### Changed
- Fix(network): Active probing for offline detection on LAN (Task T1465)
- Export: fix network failure handling and floor-filtered export nav
- Export: fix network failure handling and floor-filtered export nav
- Export: fix network failure handling and floor-filtered export nav
- Refine analyzer surgical split logic to be per-file and dynamic
- Checkpoint before delegating D001 to Jules

## [4.16.1] - 2026-02-18

### Changed
- Fix(export): disable looking mode during scene animations
- Fix(network): implement active probing for offline detection to resolve unreliability on LAN

## [4.16.0] - 2026-02-18

### Added
- Refine linking mode UI with minimalist top instruction bar

## [4.15.0] - 2026-02-18

### Added
- Add linking mode instruction and update notification

## [4.14.0] - 2026-02-18

### Changed
- **Exports**: Restored default HD export window dimensions (landscape) while maintaining compact UI elements.
- **Exports**: Implemented `is-hd-export` specific styling for floor buttons and room labels.
- Stabilize hotspot auto-forward toggle reliability and export consistency
- **Exports**: Implemented "Lazy Drift" navigation mode with Move cursor.
- **Exports**: Snappier drift (2.2x speed) with premium fade-out damping when leaving viewer stage bounds (20% -> 0% over 50px) (not just window).
- **Exports**: Added visual "Move" cursor (Lucide icon) to exported tours.
- **Builder**: Added "Move" icon to internal Lucide library.
- Exports: Tune lazy drift responsiveness and dampening
- Exports: Lazy Drift navigation with premium damping
- Exports: Tweak lazy drift stop distance to 50px
- Refine export visuals: 4k logo sizing, 2k window support, and pannellum spinner color
- Refine room label visuals: remove shadows from builder and export persistent labels
- Refine HD export UI: Force compact navigation, keep original logo size
- Fix build: update unit tests for TourTemplateScripts signature change
- Pretty Polished and Stable

## [4.14.0] - 2026-02-17

### Changed
- Feat(ui): refine visual pipeline with golden ratio proportions, glassy aesthetic, and safe-zone wrapping
- Fix label menu keyboard interception, improve empty label naming logic, and add Unicode/Arabic support for scene filenames
- Fix export auto-forward by scene double-chevron route and runtime reliability
- Fix export auto-forward by scene double-chevron route and runtime reliability
- Refine visual pipeline connector rendering and start/end node styling
- Perfect combo of visual pipeline auto-forward look and feel
- Refining Visual Pipeline Appearance: Centered Right Chevron for Auto Forward Scens
- Task 1448: Network Stability Masterplan + 13 sub-tasks (1449-1461)
- Match auto-forward chevron in exported tours to app styles
- Apply Indigo (#4B0082) styling to auto-forward buttons and indicators
- Indigo Export Auto-Forward, Confident Build
- Network Stability Masterplan: Batch 2 Merged. Foundation for request queue, auth client, and persistence hardened.
- Network Stability Masterplan Final: All 13 sub-tasks completed. Hardened network resilience, offline awareness, and crash recovery.

## [4.13.0] - 2026-02-17

### Changed
- Viewer responsive hfov + portrait fallback + ui sizing fixes
- Viewer responsive hfov + portrait fallback + ui sizing fixes
- Responsive fallback policies for builder and export tours
- Responsive fallback policies for builder and export tours
- Stabilize 3-state viewer modes, compact HUD alignment, and postpone visual pipeline calibration
- Finalize export UX with standalone-first launcher, shared assets, and deployment guidance
- Update exported hotspot styling: 28px size, 10px radius
- Fix project load validation truthfulness and harden save/load asset consistency
- Fix project load validation truthfulness and harden save/load asset consistency

## [4.13.0] - 2026-02-16

### Changed
- V4.13.0+7 [TRIPLE]: Unit test audit and maintenance (Task 1412); consolidated reducers, updated adapter naming, added missing core tests, and aligned regressions
- Stabilize export flow and add dual web_only + standalone package output
- Stabilize export parity: fix logo packaging, hotspot visual parity, and single-toggle state sync
- Stabilize export parity: fix logo packaging, hotspot visual parity, and single-toggle state sync
- Progress checkpoint: export waypoint autoplay flow, hotspot clickability, and b-spline-only spline policy
- Progress checkpoint: export waypoint autoplay flow, hotspot clickability, and b-spline-only spline policy
- Export stability hardening and app-wide scene.id hotspot targeting migration
- Export stability hardening and app-wide scene.id hotspot targeting migration
- Export waypoint parity fix and close T1426

## [4.13.0] - 2026-02-15

### Added
- Complete tasks 1402 1405 1406 1407 1408 1409 1410 1412 and archive 1413; deliver D001 D003 D004 D005 D007 D009 with D008 deferred, including auth hardening, visual pipeline optimization, teaser/headless + abort unification, telemetry governance, and API/dead-code alignment

### Changed
- Complete D001-D005 dev tasks: teaser/backend surgical refactors, AST-accurate spec_diff verification, data-flow integration, and completed-task archive consolidation
- Complete D001-D005 dev tasks: teaser/backend surgical refactors, AST-accurate spec_diff verification, data-flow integration, and completed-task archive consolidation
- Finalize regenerated dev tasks: classify backend models_common and integrate backend model/support modules into data flows
- Finalize regenerated dev tasks: classify backend models_common and integrate backend model/support modules into data flows
- Fix project-load viewer auth path (dev proxy) and token cookie sync; include ServiceWorkerMain formatting
- Fix project-load viewer auth path (dev proxy) and token cookie sync; include ServiceWorkerMain formatting

## [4.12.0] - 2026-02-15

### Added
- Complete tasks 1402 1405 1406 1407 1408 1409 1410 1412 and archive 1413; deliver D001 D003 D004 D005 D007 D009 with D008 deferred, including auth hardening, visual pipeline optimization, teaser/headless + abort unification, telemetry governance, and API/dead-code alignment

## [4.11.0] - 2026-02-15

### Changed
- Update ViewerManager to use granular slices and remove useAppState

## [4.10.5] - 2026-02-14

### Changed
- Merge refactor-arch-consolidation-18315171441260330096 and preserve new VisualPipeline

## [4.10.4] - 2026-02-14

### Changed
- Merge and verify jules unit test coverage tasks 1372-1375
- _dev-system enhanced, will process dev tasks
- V4.10.4+2 [TRIPLE]: merge Jules surgical refactors D002-D015
- V4.10.4+3 [TRIPLE]: upgrade spec_diff to Semantic AST (Tree-sitter) & implement 30-day baseline expiry
- V4.10.4+4 [TRIPLE]: analyzer audit complete, tasks refreshed, D003 resolved
- V4.10.4+5 [TRIPLE]: documentation alignment complete - modules classified in MAP.md and integrated into DATA_FLOW.md
- V4.10.4+6 [TRIPLE]: resolve D018 by fixing analyzer tree check bug, finalize VisualPipeline merge, and refresh tasks
- V4.10.4+7 [TRIPLE]: resolve all remaining analyzer and tool warnings

## [4.10.3] - 2026-02-14

### Changed
- Harden task aggregation policy and perform massive cleanup

## [4.11.0] - 2026-02-14

### Changed
- **Task Maintenance Policy**: Hardened `_dev-system` analyzer to trigger completed task aggregation at >20 files (was 90) and maintain only the 10 most recent tasks for extreme directory leaness.
- **Project History**: Aggregated 130+ legacy task files (1230-1357) into `_CONCISE_SUMMARY.md` and purged archived `.md` artifacts.

## [4.10.2] - 2026-02-14

## [4.10.1] - 2026-02-14

### Fixed
- Align project save payload

## [4.10.0] - 2026-02-14

### Added
- Enlarge tooltips & hide toasts (scene order needs fixing)

### Changed
- Refine upload sorting and tooltip delay
- Fix scene list tooltip + quality badge

## [4.9.0] - 2026-02-14

### Added
- Update scene naming logic (EXIF sort, 00X serial) and compact tooltip

## [4.8.0] - 2026-02-14

### Added
- Scene naming now uses Label_Prefix_OriginalName format and Sidebar displays full filename

## [4.7.9] - 2026-02-14

### Fixed
- SyncInventoryNames now preserves original filename base instead of reverting to UUID

## [4.7.8] - 2026-02-14

### Fixed
- RecoverBaseName supports both new (label_prefix) and old (prefix_label) filename formats

## [4.7.7] - 2026-02-14

### Fixed
- Sidebar shows full filename and filename format follows label_prefix_base convention

## [4.7.6] - 2026-02-14

### Fixed
- Resolve build errors in label refactor

## [4.7.5] - 2026-02-14

### Fixed
- LabelMenu and SceneMutations refactored to separate label from filename generation

## [4.7.4] - 2026-02-14

### Fixed
- LabelMenu now recovers base name from current filename instead of raw ID

## [4.7.3] - 2026-02-14

### Fixed
- RESTORE missing JSX tag in ViewerLabelMenu

## [4.7.2] - 2026-02-14

### Fixed
- Sidebar/LabelMenu explicitly use active scene index for consistent labeling

## [4.7.1] - 2026-02-14

### Fixed
- Resolve build errors from deprecations and signature updates

## [4.7.0] - 2026-02-14

### Added
- Sidebar now prepends # tags to original filename instead of replacing it

## [4.6.5] - 2026-02-14

### Fixed
- Resolve rescript build lock and remove white border from logo

### Changed
- Ui: add glassmorphism effect (backdrop blur) to logo container
- Ui: reduce logo border radius from 12px to 8px
- Ui: modernize watermark with 6px radius and translucent gold border
- Ui: reduce watermark glass border padding to 1px
- Ui: reduce watermark border radius to 4px
- Ui: make logo border 100% opacity
- Ui: reduce logo border radius to 2px
- Ui: implement perfect mask clipping for logo corners
- Initial Global Logo Implementation

## [4.6.4] - 2026-02-14

### Fixed
- Support fast logo format detection (jpeg/png/webp) in viewer HUD and exporter

### Changed
- Ui: remove white border from viewer logo and use transparent overlay

## [4.6.2] - 2026-02-14

### Changed
- FIX: Linking mode bug + UI: Creative format/size badges in sidebar. NOTE: Image analysis seems broken and should be revisited.
- Extreemly stable state

## [4.6.1] - 2026-02-13

### Changed
- Classify map entries and integrate easing utility into data flows (D016, D019 handled)

## [4.6.0] - 2026-02-13

### Added
- Surgically update _dev-system to support violation skipping and de-escalate !important; de-cluttered D001 task

## [4.5.7] - 2026-02-13

### Fixed
- Restore tour naming (EXIF integration, numeric skip logic, year restoration), unify sanitized filenames in upload summary; NOTE: upload summary dialog box needs UI revision

## [4.5.5] - 2026-02-13

### Fixed
- Restore tour naming from EXIF and fix upload summary filenames

## [4.5.3] - 2026-02-13

### Fixed
- Resolve type error in ResizerLogic and prepare for task 1363

### Changed
- V4.5.4: Integrate and unify architecture (Naming, Sidebar Perf, Backend Hardening, TransitionLock Cleanup)

## [4.5.2] - 2026-02-13

### Fixed
- Snapshot toast

## [4.5.1] - 2026-02-13

### Fixed
- Guard file reader

## [4.5.0] - 2026-02-13

### Added
- Clickable Tour Preview Arrows in waypoints (limited to single-scene panning)
- Panning status to NavigationSupervisor for seamless single-scene previews without notification noise

### Fixed
- Build errors related to `Dom.getAttribute` nullable return type alignment
- Regression in `PopOver_v.test.res` and `SceneTransitionManager_v.test.res`
- Premature FSM completion during single-scene previews
- Clickable arrow animation ID mismatch causing static arrows during preview
- Use correct `String.slice` parameters in `HotspotLayer.res`
- Syntax error in `LockFeedback.res` and unused variable warnings in `NavigationController.res`
- Unified transition notification toasts

### Changed
- Fix build errors and refine single-scene preview logic for clickable arrows
- Implement smooth cinematic intro pan, leveled arrival, and waypoint visibility hardening

## [4.4.4] - 2026-02-13

### Changed
- E2E tests finished
- E2E tests finished

## [4.4.4] - 2026-02-12

### Fixed
- Harden CI budgets & E2E browser provisioning

### Changed
- E2E tests updated
- 1319 E2E Test Ingestion Import DONE and ServiceWorkerMain formatting fix

## [4.4.3] - 2026-02-12

### Fixed
- Harden backend startup resilience

## [4.4.2] - 2026-02-12

### Changed
- ARCH progress: reliability hardening across 1349-1356 (SLO observability baseline, navigation run-token foundation, scene transition idempotence, simulation stale-work guards, state-boundary migration phases 1-2, API reliability contracts, and persistence/recovery durability with schema-versioned autosave migration plus idempotent operation replay)
- ARCH 1357: backend production hardening (safe env defaults for session/CORS/rate limits/timeouts, middleware resilience under quota+shutdown stress, standardized safe temp-path and error responses, and graceful shutdown request draining semantics)
- Task 1358: add CI bundle/runtime budget gates, perf stress suite, SLO-aligned runbook, and archive task closeout
- Task 1348 progress: stabilized unit tests by fixing stale mocks/expectations and bridge-state wiring, removed zombie low-signal tests, frontend suite now green (812/812). Remaining: complete Tracks A-G acceptance criteria, run full verification matrix (npm run build, backend release build, npm test, e2e/perf), and archive task from active to completed.
- Dev tasks D012+D013: integrated navigation modules into DATA_FLOW (FloorNavigation, Actions, NavigationHelpers/State, Navigation/Logic/UI/Graph, TransitionLock context) and classified NavigationState in MAP; cleared unmapped sections. Remaining: execute unresolved enterprise hardening implementation for task 1348 Tracks A-G and complete full verification matrix before archiving 1348.
- Task 1348 Track A: added run-token guards in NavigationController to ignore stale preload/stabilize callbacks; frontend suite green (812/812). Remaining: Tracks B-G and full verification matrix (npm run build, backend release, npm test, e2e/perf) before archiving task.

## [4.4.2] - 2026-02-11

### Fixed
- Resolve simulation preview stall on second scene

### Changed
- Refactor App context bridge plumbing
- Task 1347: replace GlobalStateBridge in systems/hooks/view layer
- Fix preview transition stall and app state bridge migration

## [4.4.0] - 2026-02-11

### Changed
- V4.4.0: Pre Supervisor Stable version
- Tasks 1328-1329 completed: NavigationSupervisor created and AbortSignal bindings integrated
- 1331: [NAV-SUP 4/6] Switch Entry Points to Supervisor
- 1332-1333: Remove TransitionLock, migrate LockFeedback, update documentation
- Task 1306: Navigation Supervisor Pattern — Implementation plan created with 6 subtasks (1328-1333)
- Architecture analysis: 8 new improvement tasks (1334-1341) — notifications, state slicing, code splitting, IndexedDB quota, docs

## [4.38.3] - 2026-02-11

### Changed
- Docs: Finalize DATA_FLOW.md structure cleanup
- Refactor toast notifications: confine to viewer-container, adjust sizing and padding, and remove close button bubble.
- Standardize viewer padding and migrate to custom notification system
- Fix floor selection color during simulation mode

## [4.38.2] - 2026-02-11

### Changed
- Docs: Complete D005 integration and finalize DATA_FLOW.md

## [4.38.1] - 2026-02-11

### Changed
- Docs: Integrate unmapped modules into DATA_FLOW.md (D005)

## [4.38.0] - 2026-02-11

### Changed
- Refactor: Center modals and dialogs relative to viewer container
- Docs: Integrate unmapped modules into DATA_FLOW.md and unify notification flows (Task D005)

## [4.36.0] - 2026-02-11

### Changed
- All tests and E2E finished

## [4.36.1] - 2026-02-10

### Fixed
- Resolve E2E teaser recording failure by correcting the CSS selector for the active canvas in `TeaserRecorder.res`.
- Fix deprecated `Js.Global.setTimeout` usage in `TeaserRecorder.res`.

## [4.36.0] - 2026-02-10

### Changed
- Feat(dev-system): relax architectural constraints and complexity weights
- Fix teaser recording CSS selector and deprecated setTimeout
- Finalize simulation and teaser fixes (Task 1316)
- Fix 401 Unauthorized during export and improve E2E observability
- Sync MAP.md and clean up test artifacts
- Fix 401 Unauthorized during export and improve E2E observability
- Fix all failing Vitest unit tests

## [4.34.28] - 2026-02-10

### Changed
- Fix(sim): repair simulation teaser tests and timeouts

## [4.34.27] - 2026-02-10

### Fixed
- Resolve E2E simulation and teaser test failures by improving state visibility, increasing timeouts, and fixing recorder initialization

## [4.34.25] - 2026-02-10

### Changed
- Archive completed task 1315

## [4.34.24] - 2026-02-09

### Changed
- Chore(sync): solidify robustness fixes across branches

## [4.34.23] - 2026-02-09

### Changed
- Fix(tests): resolve robustness suite failures and improve network logic

## [4.34.22] - 2026-02-09

### Changed
- Fix type inference and missing module references

## [4.34.0] - 2026-02-09

### Added
- Implement recovery modal detection system for interrupted operations

- Add emergency queue mechanism using localStorage for fast operation persistence
- Implement interrupted operation detection on page reload
- Create synthetic interrupted entries when emergency flag detected
- Ensure recovery modal is dispatched with correct operation details
- Add comprehensive logging for recovery system debugging
- Verify ModalContext receives and renders recovery prompt

Fixes Task 1311: Recovery modal now properly detects interrupted save operations after browser refresh

## [4.33.12] - 2026-02-09

### Changed
- Sync branches and service worker update

## [4.33.11] - 2026-02-09

### Fixed
- Resolve rapid scene switching hangs in Firefox

## [4.33.10] - 2026-02-09

### Changed
- Merge fix-hotspot-nav-e2e-12149307716369964221 and finalize task 1308
- V4.33.11+0 [TRIPLE]: merge 4 pending fixes (performance, upload, sidebar sync, rapid switch)

## [4.33.9] - 2026-02-08

### Changed
- Chore(structure): integrate new notification, lock, and hook modules into MAP

## [4.33.8] - 2026-02-08

### Changed
- Add e2e investigation tasks and harden transition lock

## [4.33.7] - 2026-02-08

### Changed
- Move master task 1307 to completed

## [4.33.6] - 2026-02-08

### Changed
- Merge robustness-structural-fixes-2815953726193619649 and finalize task 1307

## [4.33.5] - 2026-02-08

### Changed
- Merge robustness-hardening-backend-fixes-7040885875031960197 and finalize tier 2 task

## [4.33.4] - 2026-02-08

### Fixed
- Versioning system correctness (5 issues)

## [4.33.3] - 2026-02-08

### Changed
- Finalize robustness tier 1 task move and master task update

## [4.33.2] - 2026-02-08

### Changed
- Merge origin/fix/robustness-hardening-frontend-3087494276489123689 and fix tests

## [4.33.1] - 2026-02-08

### Changed
- Fix backend panic and pannellum filereader exception
- Break down Task 1307 into manageable subtasks

## [4.33.0] - 2026-02-07

### Added
- Fix VisualPipeline initialization and E2E responsiveness

### Changed
- Enhance VisualPipeline visibility and responsiveness

## [4.31.4] - 2026-02-07

### Fixed
- VisualPipeline initialization race condition and timeline updates

## [4.31.3] - 2026-02-07

### Changed
- Chore: consolidate changelog for v4.31.2

## [4.31.2] - 2026-02-07

### Fixed
- **UI Interaction & Debouncing (Task 1300)**: Resolved critical interaction blocking and event handling issues.
  - Implemented `minIntervalMs` enforcement in `SlidingWindow` interaction policy to prevent rapid click floods (e.g., Save button).
  - Fixed viewer utility bar click timeout by making `#viewer-stage` responsive and increasing its `z-index` above the sidebar.
  - Unified notification rendering by consolidating duplicate toast providers and enabling rich colors for state feedback.
  - Resolved autopilot interaction blocking by precisely targeting the sidebar for pointer-event suppression during simulation.

## [4.31.0] - 2026-02-07

### Changed
- Chore(tasks): Update task management procedures and archive notification tasks

- Update CLAUDE.md: Add blocking requirement to read tasks/TASKS.md before task creation
  * Make it explicit that tasks are file-based (.md files), NOT TaskCreate tool
  * Prevent incorrect abstract task creation in future
  * Reinforce workflow: Create in pending/ → Move to active/ → Complete → Archive in completed/

- Create task 1276: Comprehensive Testing Plan for FSM-Lock Synchronization Fixes v4.30.0
  * Full test methodology for validating FSM-Lock coordination fixes
  * 6 test categories covering basic loads, rapid clicks, lock verification, notifications, regressions, edge cases
  * Quick test (10min) and full test (30min) flows with success criteria

- Archive completed notification architecture tasks with _DONE postfix:
  * 1272a_Unify_Notifications_High_Migration_DONE.md
  * 1272b_Unify_Notifications_Medium_Migration_DONE.md
  * 1272c_Unify_Notifications_Final_Migration_DONE.md
  * 1273_Mount_NotificationCenter_in_App_DONE.md
  * 1274_Integration_Testing_and_Verification_DONE.md
  * 1275_Performance_Profiling_and_Optimization_DONE.md

- Evaluated postponed tasks (1243, 1246): Recommend keeping postponed
  * Neither related to v4.30.0 FSM-Lock work
  * Both valid UX improvements but not blockers
  * Can be batched into future "UX Polish" epic

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
- Half Stable UI

## [4.30.0] - 2026-02-07

### Changed
- Fix(fsm-lock): Synchronize state machine and lock lifecycle for reliable scene transitions

Core fixes:
- Handle TransitionLock.acquire() failures with automatic 100ms retry
- Detect and ignore mismatched TextureLoaded events (prevents FSM freeze)
- Implement phase-specific lock timeouts: Loading(15s), Swapping(8s), Cleanup(3s)
- Add FSM state logging for visibility into transitions
- Remove redundant "System is busy" notification from SceneList

Result: Scenes now load smoothly without 15-second freezes, lock releases properly in 1-2 seconds, and rapid scene clicks are handled gracefully through retry logic.

Notification improvements:
- Moved LockFeedback to top-right corner (professional unified location)
- Consolidated from 3 sources to 2: SceneItem throttle + LockFeedback countdown
- Clean, consistent user feedback for scene transition status

Testing verified:
✓ Single scene clicks load smoothly
✓ Rapid scene clicks handled without lock freeze
✓ Scene interruption works correctly
✓ Lock timeout reduced from 15s to natural release (1-2s)
✓ No React rendering errors
✓ Notifications appear in consistent location

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## [4.28.1] - 2026-02-06

### Changed
- Fix pre-push hook excessive large file scanning

## [4.28.0] - 2026-02-06

### Changed
- Analysis complete: Created 1260_implement_global_interaction_guard
- Eliminate structural race conditions: TransitionLock, Batch actions, ID-based resolution

## [4.26.0] - 2026-02-06

### Changed
- Add task 1260: Integrate DataFlow Modules
- Create AGENTS.md as universal agent guidelines
- Optimize .gitignore: exclude dev-system build artifacts and logs
- Task 1259 created

## [4.24.6] - 2026-02-06

### Changed
- Merge fixes for upload preloading, resizer memory stats, and journal cleanup with tests.

## [4.24.5] - 2026-02-06

### Changed
- Merge fixes for upload preloading, resizer memory stats, and journal cleanup with tests.

## [4.24.4] - 2026-02-06

### Changed
- Merge pull request fix/fsm-interaction-overhaul-7792785592159946274: UX and FSM locking improvements
- Improving UI in progress
- Improving UI in progress

## [4.24.3] - 2026-02-06

### Changed
- Task: number 1256 and update CLAUDE.md & task details for FSM overhaul

## [4.24.1] - 2026-02-06

### Changed
- Fix analyzer regex & 100% Data Flow coverage 🌊

## [4.25.0] - 2026-02-06

### Fixed
- Corrected regex in `_dev-system/analyzer/src/guard.rs` to accurately capture multiple module references per line in `DATA_FLOW.md`.

### Changed
- Reorganized `DATA_FLOW.md` for better token efficiency and readability using directory-based grouping.
- Achieved 100% architectural coverage in `DATA_FLOW.md`, integrating all project modules into logical flows.
- Verified analyzer self-healing: automated task cleanup and dynamic unmapped module tracking are fully operational.

## [4.24.0] - 2026-02-05

### Changed
- Implement FSM-based state management and remove InteractionQueue

## [4.23.1] - 2026-02-05

### Changed
- Fix duplicate detection to prioritize deleted scenes for re-upload

## [4.23.0] - 2026-02-05

### Changed
- Fix black image bug: Align Upload keys with Reducer, add log cleanup & telemetry

## [4.21.0] - 2026-02-05

### Changed
- Add comprehensive task for fixing black image persistence issue (Task 1249)

## [4.19.4] - 2026-02-05

### Changed
- Update changelog with reliability details

## [4.19.3] - 2026-02-05

### Changed
- **Reliability & Optimization**: Implemented upload batching (5 items/batch) and throttled journal updates to reduce reducer overhead and IDB pressure.
- **Persistence**: Added user notifications for auto-save failures to prevent silent data loss.
- **Stability**: Enhanced InteractionQueue with error escalation and recovery notifications on stability timeouts.
- **Security**: Restricted `dev-token` usage to `localhost` and `127.0.0.1` to harden production environments.
- **Tasks**:
  - Completed Task 1244: Synchronized Circuit Breaker notifications with UI layers.
  - Completed Task 1248: Unified codebase classification for new recovery and persistence modules in `MAP.md`.
  - Completed Task 1249: Fixed recovery modal race condition on browser refresh with a 500ms stabilization delay.

## [4.19.2] - 2026-02-04

### Changed
- Finalized merge of fix-rapid-save-notification-stability with test stabilization

## [4.19.1] - 2026-02-04

### Changed
- Merge fix-zip-import-selector and fix formatting

## [4.19.0] - 2026-02-04

### Changed
- Implement Formula v2.0: Eliminate double-counting, optimize weights for AI comprehension
- Maintenance: Clean up MAP.md, aggregate tasks, and silence analyzer test logs
- Create and enhance reliability tasks based on E2E test audit

## [4.18.1] - 2026-02-04

### Changed
- Merge tactical upload recovery task-1228

## [4.18.0] - 2026-02-04

### Added
- Evaluate and merge PR 1227 - Project Save Recovery

## [4.16.3] - 2026-02-04

### Changed
- Merge PR 1226: Complete Optimistic Update and Recovery Integration

## [4.16.2] - 2026-02-04

### Changed
- Merge PR 1226: Complete Optimistic Update and Recovery Integration

## [4.16.1] - 2026-02-04

### Changed
- Re-organize and re-number pending tasks for prioritized robustness rollout

## [4.16.0] - 2026-02-04

### Added
- Brainstorm retry logic & create recovery tasks (1223, 1224, 1225)

## [4.15.0] - 2026-02-04

### Added
- Complete E2E critical path coverage with simulation, recovery, and performance suites (Task 1222)

### Changed
- Housekeeping: archive completed tasks 1202, 1205, and 1222

## [4.14.0] - 2026-02-04

### Added
- Merge PR #133 and complete commercial readiness audit

- Merged PR #133: Expand E2E Robustness Test Suite
  - Added 12 comprehensive E2E tests covering robustness patterns
  - Tests: Circuit Breaker, Retry Backoff, Optimistic Rollback, Rate Limiting
  - Increased E2E coverage from 10% to 40%

- Created comprehensive commercial readiness audit documents
  - docs/COMMERCIAL_READINESS_AUDIT.md (17KB detailed analysis)
  - docs/AUDIT_EXECUTIVE_SUMMARY.md (7.8KB executive summary)
  - Overall score: 7.5/10 → 8.0/10 after PR merge

- Created Task 1222: Complete E2E Critical Path Coverage
  - Roadmap to achieve 80% E2E coverage
  - 5 test suites planned (Upload→Export, Save→Load, Simulation, Error Recovery, Performance)
  - Target: Commercial Grade Score 9.0/10

Key Findings:
- ✅ World-class type safety (zero unwrap(), zero console.log)
- ✅ Sophisticated robustness patterns (Circuit Breaker, Retry, Optimistic Updates)
- ✅ Self-governing development system (_dev-system analyzer)
- ⚠️ E2E test coverage needs expansion (40% → 80%)
- ⚠️ Security: Dev token fallback needs environment check
- ⚠️ IndexedDB quota monitoring needed

Recommendation: Approve for commercial release after completing Task 1222

## [4.13.0] - 2026-02-04

### Added
- Merge PR #132 (JSON Combinators), update MAP.md, create task 1220 for optimistic update completion

### Changed
- Refactor dev-system analyzer: Extract main.rs into focused modules (860→266 LOC)

## [4.12.0] - 2026-02-04

### Changed
- Add ID collision hardening to Task 1208 and resolve task ID collision

## [4.11.0] - 2026-02-04

### Changed
- Merge task-1205: Implement Operation Journal and Mid-flight Recovery

## [4.9.0] - 2026-02-04

### Added
- Implement Smart Versioning and build reset logic

## [4.8.15] - 2026-02-04

### Changed
- Merge task/1203: Implement Debounce and Rate Limiting for heavy operations
- Implement Abort support and cancellation for Save/Export
- Final sync: Implementation of Throttled Action with Abort support and UX refinements
- Merge task-1204: Implement Request Retry with Exponential Backoff and update related E2E tests task

## [4.8.18] - 2026-02-03

### Added
- **Human Inertia Smoothing (Freehand Pathing)**: Implemented a 2-pass weighted inertia filter for waypoint paths in `PathInterpolation.res`.
- Guaranteed "Wide Turns": The system now "stiffens" path endpoints while filleting inner corners to simulate human head pivots and eyes movement.
- `waypointSmoothingFactor`: Centralized smoothing control in `Constants.res` (set to 0.3).

### Changed
- **Unified Pathing**: Both Red (Camera) and Yellow (Floor) draft lines now share the same B-Spline interpolation engine as the final tour paths.
- **Improved Anchoring**: Strictly pinned floor paths to the Rod Base in Linking Mode to prevent visual "drifting."

### Refactored
- **HotspotLine System Cleanup**:
    - Renamed the redundant `HotspotLineLogicLogic.res` to `HotspotLineDrawing.res`.
    - Consolidated common types and caches into `HotspotLineState.res`.
    - Resolved circular dependencies by isolating state from rendering and animation logic.

## [4.8.17] - 2026-02-03

## [4.8.16] - 2026-02-03

### Added
- Initialize Robustness Task Suite: Updated 1200, created 1201-1207 (Circuit Breaker, Rollback, Debounce, Retry, Recovery).
- Implement mandatory `rescript-json-combinators` standard for all new robustness tasks.

## [4.8.15] - 2026-02-03
- Fix navigation hang and throttle telemetry flood; Add 1199 E2E task
- Synchronization and version bump
- Final Sync: Unify E2E task and async fixes across branches
- Completed task 1199: Comprehensive Playwright E2E Automation
- Fix E2E test duplicate detection and improve InteractionQueue stability
- Add diagnostic logging to NavigationController Stabilizing state
- Fix tour preview hang and stabilize rapid scene switching
- Arch: implement system-wide robustness and ai-diagnostic e2e suite
- Tasks: apply mandatory sequential numbering to robustness task

### Fixed
- Update Constants test timeout and add unit tests for SceneMutations and ExifUtils
- Release barrier lock earlier in InteractionQueue to allow initial scene load
- Lock viewer HFOV at 90, disable zoom, and restore app unit tests

### Changed
- Initialize Robustness Task Suite (updated 1200, created 1201-1207)
- Analyze _dev-system and create Task 1208 for analyzer improvements
- Merge pull: system-robustness-v2-5500292857890026552 and complete Task 1200
- Stable UI tour preview & load project
- Waypoint Perfect Smoothing Factor
- Merge and verify optimistic-update-rollback: Infrastructure, tests, and MAP.md updates

## [4.8.15] - 2026-02-02

### Refactored
- De-bloated backend modules: `main.rs` (357 -> 189 LOC) and `auth.rs` (307 -> 99 LOC).
- Extracted backend sub-modules: `auth/jwt.rs`, `auth/middleware.rs`, `startup/logging.rs`, `startup/config.rs`, and moved API configuration to `api/mod.rs`.
- **Upgraded `_dev-system` (v1.6.0)**:
    - Implemented **Hysteresis (Dead Zone)** to prevent Split/Merge circular loops.
    - Added **Architectural Targets** to Surgical tasks (explicit module split counts).
    - Added **Shadow Orchestrator Detection** to protect intentional sub-module groupings.
    - Implemented **Folder Flattening** in Merge directives to reduce directory nesting tax.
    - Unified stability logic by validating merges against hypothetical surgical limits.

### Fixed
- Viewer loading failure after project import by restoring proper viewport statuses in `ViewerSystem.Pool.reset`.
- Potential stale state issues by ensuring `ViewerSystem.resetState` is called during project load.
- Restore viewer functionality after project import by fixing Pool.reset
- Eliminate legacy svg hotspots and resolve navigation state desync
- Frontend violations, interaction queue immutability, and backend safety improvements
- Resolve build and test failures after merging task-1194

### Changed
- Investigating scene transition problem in tour preview autopilot mode
- Merge branch 'fix-tour-preview-hang-18228800889238016474' into main: Fix tour preview hang by handling scene load timeouts and errors
- Add task to fix tour preview transition block and document scene load errors
- Merge auth subsystem into unified auth.rs module

### Merged
- Task 1194: Comprehensive Test Coverage Hydration.
    - Audited codebase for test parity and synchronized Vitest suite.
    - Added unit tests for `JsonParsersShared.res` and `ApiHelpers.res`.
    - Created granular test tasks for `Teaser`, `ViewerLogic`, and UI components (1195-1199).
    - Fixed compilation warnings and placeholder tests in `ViewerManager_v.test.res`.

### Added
- Create architecture task for serial interaction queue (1185)
- Backend refactor (Task 1176) & _dev-system upgrade (v1.6.0)

## [4.8.14] - 2026-02-01

### Fixed
- Merge project import image fix and sync SW
- Resolve image loading issues & secure project handling [CSP]
- Project import image loading by handling null files and improving URL reconstruction fallback
- Viewer loading by hooking up Pannellum load events and fixing hook violation in FloorNavigation
- Viewer rendering visibility (Task #885) - invalidate stale blob URLs

### Changed
- Merge sanitization standards PR
- Use non-blocking I/O in backend async handlers
- V4.8.14+385 [TRIPLE]: merge: frontend unit tests PR & document failures
- V4.8.14+386 [TRIPLE]: merge: infrastructure fix PR, cleanup obsolete artifacts & create fix task
- Parser perfected, images loaded to sidebar, but window viewer still not loads
- Fix navigation FSM deadlock and improve project import URL reconstruction (v4.8.14+391)
- Add investigation task for viewer rendering issue (v4.8.14+392)
- Final sync and build check

## [4.8.13] - 2026-02-01

### Changed
- **Perf(Backend)**: Implemented comprehensive async I/O for multipart uploads, project imports, and video processing.
  - Replaced blocking `std::fs` with `tokio::fs` across `project_multipart.rs`, `video.rs`, and `project.rs`.
  - Introduced `tokio::io::BufWriter` for optimized large file writes during video uploads.
  - Offloaded blocking zip extraction and cleanup tasks to Actix thread pool via `web::block`.
  - Added performance benchmarks and unit tests for multipart and video processing.
- Refactor(Core): Replaced rescript-schema with rescript-json-combinators for full CSP compliance
- Perf(Backend): Async I/O & Core: Schema Migration to Combinators
- Ui: update toast colors and sanitize json errors
- Ui: premium toast styling and ruthless json sanitization
- Synchronize codebase map, classify JsonParsers, and clean up stale tasks
- Preserve analysis reports and dev-system refinement history
- Final repository cleanup and automated plan updates
- Fix(project-manager): use safe json encoding for project load (sidebar images fixed, viewer pending)
- Cleanup unused imports in media/serve.rs
- Add debugging logs for image serving
- Black image bug persists, image not loading

### Fixed
- Improve MIME sniffing in backend and bust SW cache to resolve black images
- Disable etag to force correct content-type propagation
- Add cache-control headers to prevent stale mime types
- Final verification of image cache control
- Fallback to main file if tinyFile is empty to prevent black images

## [4.8.12] - 2026-01-31

### Changed
- Merge(migrate-json-to-schema): Complete migration of legacy JSON handling to type-safe Rescript Schema validation across core systems (API, Telemetry, Templates)
- Delete(ProjectData.res): Removed legacy serialization module in favor of schema-driven transformations
- Doc(Standards): Mandated `rescript-schema` usage in `GEMINI.md` and workflow standards
- Fix(SessionStore): Resolve compilation errors for JsExn and migrate from Console to Logger
- Harden(Persistence): Secure autosave and project loading with declarative schema boundaries
- Fix(rules): Replace forbidden Obj.magic in AsyncQueue.res with safe error handling and logging
- Merge Core, Systems, and Backend Auth refactors
- Fix(dev-system): update merge directive to strip efficiency tags
- Post-merge sanitation of efficiency tags
- Merge refactor-systems-frontend and sanitize
- Modularize pathfinder, consolidate upload, and fix circular navigation dependency
- Fix(rules): Replace forbidden Obj.magic in AsyncQueue.res with safe error handling and logging
- Doc(map): Classify AsyncQueue.res in Utilities & Infrastructure
- Fix(rules): Replace Obj.magic in AsyncQueue.res & classify in MAP.md
- Fix MAP.md zombie entries and enhance analyzer guard logic
- Create task for Rescript Schema migration
- Merge migrate-json-to-schema branch and resolve SessionStore compilation issues
- Finalize rescript-schema migration and update project standards
- **Feat(Logging)**: Implement unified diagnostic logging system (Frontend + Backend)
  - Configure dual backend logging sinks (`diagnostic.log`, `error.log`) with JSON formatting
  - Implement real-time Diagnostic Mode toggle in About dialog box
  - Enable live telemetry streaming (bypassing batching) when Diagnostic Mode is ON
  - Add backend panic hook to capture unhandled exceptions in tracing
  - Intercept high-value UI events (notifications, modals, processing) for automatic telemetry
  - Synchronize `tail-diagnostics.sh` for formatted real-time multi-source log viewing
  - Fix trace correlation with `X-Request-ID` injection and `requestId` field synchronization
- **Refactor**: Move diagnostic toggle from Sidebar Branding to About dialog box to maintain clean aesthetics
- Merge test stabilization fixes
- Final standards alignment for session tests
- Fix(telemetry): harden logging pipeline and csp compliance

- [telemetry] implement crash-safe serialization fallback in frontend logger
- [telemetry] add fallback sanitized logging for malformed payloads
- [infra] relax CSP in index.html to allow 'unsafe-eval' for legacy bindings
- [backend] integrate sentry and tracing-tree for robust error tracking
- Fix(core): Resolve CSP unsafe-eval violations via zero-eval strategy
- Feat(dev-system): Update analyzer rules to enforce CSP-friendly JSON validation

### Added
- Implement unified diagnostic logging system with real-time UI toggle and live telemetry

### Fixed
- Resolve widespread test failures and schema runtime errors; restore App and ViewerManager unit tests
- Upgrade rescript-schema and restore standard serialization across systems

## [4.8.12] - 2026-01-30

### Changed
- Eliminate testing protocol for refactor phase, integrate backend/frontend systems merges, and fix unreachable module false-positives
- V4.8.12+322 [TRIPLE]: integrate backend/frontend architectural merges, finalize structural cleanup, and refresh stage-2 surgical tasks
- V4.8.12+324 [TRIPLE]: integrate backend stage-2 optimizations, refresh frontend surgical targets (Logger/Reducer), and trigger task aggregation maintenance
- Imp(dev-system): Show full file paths in Vertical Slice and Merge tasks
- Merge refactor/frontend-surgical-stage-3 and generate new system tasks
- Merge refactor/frontend-surgical-stage-3 and refactor-reducer-core-frontend

## [4.8.11] - 2026-01-30

### Changed
- Refactor: Enhance analyzer reachability & zombie elimination, purge dead code
- Dev System Finally Stable & Perfect Math
- Merge: bugfix/analyzer-empty-task-deletion and sync plans
- _dev-system unreachable modules fixed
- Fix all warnings and errors across frontend and backend
- Add task 1126: Upgrade _dev-system to Semantic Engine for 100% accuracy
- _dev-system: Upgrade to Semantic Engine v1.5.0 (AST-Parsing, Symbol-Awareness, Failure-Feedback, and Stability Guard)
- Docs: Unify _dev-system README and Manifest into a comprehensive v1.5.0 Semantic Engine Guide
- Standardize directive grouping in task generation system across all architectural categories
- Complete task 1119/1134, improve analyzer robustness, and extract frontend sub-modules

### Added
- Harmonize split/merge math and improve ReScript complexity fidelity
- Integrate state density (mutability) into Drag formula across all languages

### Fixed
- Treat mapped modules in MAP.md as entry points to prevent false-positive unreachable module flags

## [4.8.11] - 2026-01-29

### Changed
- Consolidate frontend API modules into Api.res and fix related tests
- Merge: tune-dev-system-logic-6120814584194181031
- Merge comprehensive surgical refactors for frontend logic and backend api/logic separation (Tasks 1080-1085)
- Optimize _dev-system smart-merge logic and automate ignored role classification
- Implement accuracy report recommendations and tune analyzer metrics
- Create task for perfecting _dev-system analyzer app (Phase 2)
- Improve: fix rescript dependency extraction and identify analyzer task pollution
- Add task 1104 for analyzer maintenance
- Improve: implement analyzer refinements (idempotent sync, unified merge, entry point guard)

### Added
- Refined `_dev-system` Smart Merge logic to support (Directory, Extension) grouping, preventing polyglot merge errors.
- Automated "Ignored" role classification in `_dev-system` via AI taxonomy templates.
- Improved task generation with deterministic sorting and action-based grouping for cleaner refactoring workflows.
- Optimized _dev-system task generation for domain-aware refactoring and explicit merges
- Implemented AI Strategic Directives and metadata optimization for _dev-system analyzer
- Merge backend structural refactor and frontend safety migration (Tasks 1076-1079)
- Implement zombie task elimination and adjust LOC threshold to 400

## [4.8.11] - 2026-01-28

### Added
- Architect consolidated commercial migration roadmap (900-906)
- Establish persistent data foundation (SQLite, migrations, SEO)
- Implement identity & security layer (JWT, Argon2, AuthMiddleware)
- Implement persistent asset storage and user isolation (Task 903)
- **Architectural Governor (v1.3)**: Overhauled the `_dev-system` for AI-autonomous refactoring.
  - Implemented **Drag Heatmaps** (Hotspot detection) to target specific line ranges for refactoring.
  - Added **Legacy Amnesty** rules to ignore authorized technical debt in stable files.
  - Implemented **Logic Stripping** (Comments/Strings) for 100% accurate structural analysis.
  - Added **Path-Based Strictness** (Drag Ceilings) to enforce purity in utility modules.
- Implement architectural hard ceiling and structural governance
- Implement autonomous role tagging engine with multi-language header support
- Automate formal ambiguity task synchronization with the project task system
- Transform dashboard into a dynamic Architectural Mind Map using D3.js
- Implement minimal Architectural Ledger dashboard and project-wide task sync
- Migrate JS Guard to Rust Analyzer

### Changed
- Mark task 903 as completed (Asset Persistence & Isolation)
- Feat(_dev-system): overhaul architectural governor with hotspots, amnesty, and smarter parsing
- Initialize autonomous classification task 1069
- Merge frontend auth and deprecate legacy size check
- Merge frontend auth, deprecate legacy size check, and ignore _dev-system build artifacts
- V4.8.11+227 [TRIPLE]: maintenance: aggregate completed tasks, unify test task generation, and sync MAP.md
- V4.8.11+228 [TRIPLE]: maintenance: consolidate test tasks and fix backend test imports
- V4.8.11+229 [TRIPLE]: fix: resolve analyzer, backend, and rescript warnings
- V4.8.11+230 [TRIPLE]: maintenance: optimize test task generation and clean up unified test task
- Refine `_dev-system` analyzer: focus on core logic (`.rs`, `.res`), fix depth calculation, and align `MAP.md` entries with project protocols.
- Refine: dev-system analyzer (core focus, depth fix, protocol alignment)

## [4.8.10] - 2026-01-28

### Changed
- Synchronize architecture and api routing fixes

## [4.8.8] - 2026-01-28

### Changed
- Integrate schema fixes and update tests
- Final integration of Jules' async schema improvements
- Safe integration of Jules' latest similarity schema updates
- Synchronize stable schema and similarity updates across all branches
- Integrate Jules' async schema fix

### Fixed
- Resolve async schema conversion error and geocode response mapping
- Resolve persistent async schema error and restore stable API structure

## [4.8.8] - 2026-01-27

### Changed
- Decompose Schemas.res and update MAP.md classifications
- Update GEMINI.md with MAP.md integrity rule
- Finalized and cleaned up batch of unified test tasks (802-820)

### Fixed
- Resolve project loading and metadata parsing issues in ReScript 12

## [4.8.7] - 2026-01-27

### Changed
- Optimize commit workflows to skip tests and auto-push
- Restrict fast-commit and commit to development branch
- Rename Testing branch to testing

## [4.8.6] - 2026-01-27

### Changed
- Update project specs with Schema and Zero Warning policies

## [4.8.5] - 2026-01-27

### Fixed
- Resolve build errors and enforce strict warning level

## [4.8.4] - 2026-01-27

### Added
- Implement ReScript Schema validation (Task 600)

## [4.8.3] - 2026-01-27

### Changed
- Refactor API schemas to use rescript-schema

## [4.8.2] - 2026-01-27

### Changed
- Decompose oversized modules (ViewerManager, HotspotLine, HotspotLineLogic, UploadProcessorLogic)

## [4.8.1] - 2026-01-27

### Changed
- Refactor(backend): Stream ZIP uploads & fix upload panic

## [4.8.0] - 2026-01-27

### Changed
- Ready Before Refactoring 360
- Complete tasks 604-743: Comprehensive refactoring of ReBindings, SceneList, Sidebar, VisualPipeline, SceneHelpers, ProjectManager, SceneLoader, Logger, and Backend modules; synced MAP.md
- Refactor: Decomposed oversized modules (SidebarMain, ExifReportGeneratorLogic, SceneLoaderLogic, analysis.rs) into focused sub-modules; Updated MAP.md
- Fix: Resolved build errors in ExifReportGenerator and SceneLoader; cleaned up unused opens for Zero Warning protocol
- Fix: Backend panic in media analysis via correct histogram vector sizing; final cleanup of unused opens
- Fix: Deadlock in geocoding service by standardizing lock acquisition order
- Fix: Backend test race conditions by enforcing serial execution in pre-push hook
- UI: Standardize dialog box styles & deactivate startup recovery popup
- Sync branches and fix race conditions in geocoding tests
- Refactor backend ZIP processing to use streaming and temp files (Task 798)
- Implement backend asset path sanitization (Task 799)
- Manual checkpoint requested by user

## [4.8.0] - 2026-01-26

### Added
- Implement comprehensive test suite for viewer components, optimize SvgManager, and resolve build warnings

### Changed
- **Performance & Safety (Task 595)**: Refactored `SvgManager.res` to eliminate unsafe type casting.
  - Replaced `Obj.magic(None)` hack with type-safe `Dict.delete`.
  - Updated `remove` function to explicitly clear the internal element cache, preventing memory leaks and stale references.
  - Added unit tests for cache invalidation and stale element recovery.
- Refactor SvgManager for safety and cache integrity (Task 595)
- Fix React empty src warnings in SceneList (Task 596)
- Strictify Transition Types
- Add unit tests for SceneCache
- Update SceneHelpers tests and fix sessionId parsing
- Update ViewerSnapshot unit tests with edge cases
- Perfected upload summary v1
- UI Standardization CSS & Icons

### Fixed
- Resolve React hook dependency mismatch in SimulationDriver and sync local changes

## [4.8.0] - 2026-01-25

### Changed
- **Surgical Refactor (Task 581)**: Successfully decoupled `ViewerManager` from raw input handling and physics.
  - Extracted mouse/pointer normalization to `InputSystem.res`.
  - Moved yellow rod velocity smoothing to `CursorPhysics.res`.
  - Isolated linking mode click handlers to `LinkEditorLogic.res`.
  - Relocated `ViewerFollow.res` from components to systems.
  - Moved `ViewerState.res` and `ViewerTypes.res` to `src/core` to resolve circular dependencies and establish a clean Directed Acyclic Graph (DAG).
- Refactor ViewerManager: Separate Input & Physics Logic (Task 581)
- Refactor UploadProcessorLogic: Extract ImageValidator, FingerprintService, PanoramaClusterer
- Complete tasks 586, 587, 588

## [4.7.11] - 2026-01-25

### Changed
- **UI Refinement**: Adjusted the room label height to **27px** and tighter padding to improve the persistent label aesthetics.
- Simulation stop hang fixed
- Scene switching race condition fixed
- Cubic-B-Spline Waypoint Smoothing applied to tour preview

## [4.7.10] - 2026-01-25

### Changed
- **Visual Standardization**: Updated "Label Menu" selection and "Clear Links" action to use a standardized **Light Orange** flicker (`#ffedd5`) matching the app's primary palette.
- **Refinement**: This change unifies the feedback color for non-destructive actions while keeping "Delete Scene" (Red) distinct. Hotspot feedback logic remains untouched.

## [4.7.9] - 2026-01-25

### Fixed
- **Animation Conflict**: Resolved background color glitches in `SceneList` animations by using pure additive overrides (`animate-flicker-*-flat`) instead of toggling transparency.
- **Sync**: Introduced `animate-flicker-yellow-flat` to perfectly match the speed and easing of the red delete flickering, ensuring a unified feel for the "Clear Links" action.

## [4.7.8] - 2026-01-25

### Changed
- **UI Contrast**: Updated "Delete Scene" menu action to use a lighter red flicker (`#fee2e2`) instead of dark red, ensuring text legibility during the confirmation animation.

## [4.7.6] - 2026-01-25

### Fixed
- **Menu Interaction**: Fixed `SceneItem` action menu not automatically closing after "Clear Links" or "Delete" actions.
- **Visual Consistency**: Standardized "Clear Links" feedback to Yellow (matching Label Menu) while keeping "Delete Scene" as Red.

## [4.7.5] - 2026-01-25

### Added
- **Visual Feedback**: Implemented double-flicker animations for enhanced user feedback.
  - **Label Selection**: Yellow flicker confirmation when selecting a room label.
  - **Scene Management**: Red flicker warning when deleting scenes or clearing links.

## [4.7.4] - 2026-01-25

### Changed
- **Sidebar UX**: Deprecated and removed the Indoor/Outdoor toggle button from the primary utility bar.
- **Tooltip Interaction**: Refined Label Menu tooltip logic to prevent visual overlap when opening context menus.

### Performance
- **React.memo Implementation**: Applied `React.memo` to `Sidebar`, `SceneList`, and `SceneItem` to block unnecessary re-renders during camera rotation.
- **Handler Stabilization**: Wrapped principal event handlers in `useMemo` to maintain prop stability, ensuring `React.memo` effectiveness in virtualized UI layers.
- **ViewerUI Optimization**: Memoized the primary `ViewerUI` HUD and stabilized its handlers to improve UI responsiveness.

### Fixed
- **Simulation Stability**: Enhanced `StopAutoPilot` logic to explicitly cancel navigation and reset state, preventing residual movement or "ghost" travel states.

## [4.7.3] - 2026-01-25

### Fixed
- **Auto-Pilot Logic**: Resolved a critical bug where Auto-Pilot would stop working due to stale state snapshots in specialized contexts.
- **UI Performance Optimization**: Implemented Domain Slices in `AppContext` to surgically provide state updates to `ViewerUI`, `Sidebar`, and `SceneList`, drastically reducing unnecessary re-renders while maintaining data freshness.
- **Test Integrity**: Updated unit tests to support the new slice-based provider architecture.

## [4.7.0] - 2026-01-25

### Added
- **Retained-Mode SVG Management**: Introduced `SvgManager` to handle high-performance SVG reconciliation. Replaces expensive "scorched earth" `innerHTML` clearing with optimized DOM element reuse, significantly reducing layout thrashing and CPU overhead during 60fps animation loops.

### Changed
- **Simulation Visibility Refactor**: Removed aggressive global hiding of hotspot markers during Auto-Pilot. Replaced with an intelligent "Active Target" dimming system that keeps all waypoints visible while highlighting the current destination.
- **Concurrent Render Loop**: Enabled the main `HotspotLine` update loop to run concurrently with `NavigationRenderer` during simulation. 
- **Garbage Collection (Set-Based)**: Implemented a robust "Set Subtraction" algorithm for SVG management. The system now tracks IDs drawn in the current frame vs. the last frame to hide only stale elements, preventing "ghost artifacts" or random disappearances.

### Fixed
- **Stale DOM Cache Bug**: Fixed a race condition where `SvgManager` could hold references to a stale SVG container after a React re-mount. Added `syncContainer` validation to ensure all updates target the currently visible document.
- **Transitional Flicker**: Resolved waypoint flickering during scene transitions by ensuring the render loop holds the last valid state until the new scene is fully detected.
- **Event Loop Decoupling**: Decoupled `NavigationRenderer` from `HotspotLine.updateLines` to prevent redundant loop execution and simplify state ownership.
- **SVG Manager Robustness**: Improved `SvgManager` to handle display toggling via `show/hide` primitives, reducing direct property manipulation in outer logic.

## [4.6.0] - 2026-01-25

### Changed
- **Projection Performance Optimization**: Refactored `HotspotLineLogic` to pre-calculate camera inverse constants and move degree-to-radian conversions out of the inner point-projection loop.
- **Pannellum Friction Optimization**: Increased friction constant from `0.05` to `0.15` in `ViewerLoader` to improve perceived smoothness and mask micro-stuttering during camera movement.

- **Idle CPU Optimization (Lazy Performance Loop)**: Refactored the global render loop in `ViewerManager` to use a high-performance "Dirty Check" (pitch/yaw/hfov delta). Expensive DOM updates for hotspots now only trigger when the camera actually moves, resolving the "sticky waypoints" regression while maintaining ultra-low idle CPU usage.
- **Responsive Overlays**: Integrated window resize listeners to ensure SVG hotspot lines maintain visual alignment when the viewer container changes dimensions.


- **Typed DOM Events**: Standardized access to `clientX`, `clientY`, and `eventPhase` via typed bindings.
- **Safe API Decoders**: Implemented strict JSON decoders for all backend responses (Metadata, Quality, Similarity).
- **File extracted helpers**: Added `fileToBlob` and `fileToFile` to handle complex file variants safely.

### Fixed
- **Vitest Stability**: Resolved failures in `ProgressBar`, `ServerTeaser`, and `PreviewArrow` unit tests.
- Fixed `scrollTo` tracking in headless test environments.
- Corrected type mismatch in `DownloadSystem` zip handling.

### Documentation
- Updated `MAP.md` to synchronize with current project architecture, adding semantic mappings for `ReBindings`, `Main`, `App`, and `Logger`.

## [4.5.2] - 2026-01-24

### Changed
- Refined Floor Navigation buttons to use "App Orange" (`#ea580c`) for selected state background and border.
- Updated Simulation Arrow to blink between Orange and Yellow (previously Green/Yellow) for better visibility.
- Implemented "Red Alert" state for Simulation Arrow when approaching the end of a waypoint path.

## [4.5.1] - 2026-01-24

### Added
- Standardized Hotspot Menu system with configurable delays (`hotspotMenuOpenDelay`, `hotspotMenuExitDelay`).
- Interactive click feedback: 2 tactical yellow flicks for Toggle, 2 red flicks for Delete.
- Smooth icon swap animation with 360° spin for Auto-Forward setting.
- Diagonal glass shimmer effect (45-degree) for Sidebar and Hotspot buttons.
- Adaptive glass sweep speed: Faster (1.5s) for Auto-Forward, standard (4s) for Normal links.

### Changed
- Reduced Hotspot button size to 32px with balanced icon scaling (20px/18px/14px).
- Standardized corporate orange to `#ea580c` across all primary UI and Sidebar actions for superior white icon contrast.

### Fixed
- Resolved context isolation issue in `PreviewArrow` by passing state and scenes directly as props, fixing broken reactivity in Pannellum hotspots.
- Fixed instant visual feedback for Auto-Forward toggle using local state coordination.

## [4.5.0] - 2026-01-24

### Fixed
- Implemented "No Persistence on First Load" policy for project metadata (`tourName` and `activeIndex`).
- Added explicit session clearing before starting project imports in `Sidebar.res` to prevent state "bleeding".
- Updated `INITIALIZATION_STANDARDS.md` to document session lifecycle and persistence constraints.

### Security
- Your security fix here.

## [4.4.9] - 2026-01-24

### Added
- Added comprehensive unit tests for `App` component properly mocking `AppContext` state injection.
- Refactored `App.res` and `AppContext.res` to allow `initialState` prop injection for easier testing.
- Updated `commit-workflow` to use `CHANGELOG.md` as the single source of truth.

## [4.4.8] - 2026-01-24

### Added
- Neat Progress Bar Upgrade.

### Changed
- Backend cleanup, test migration to Vitest, and general updates.
- Migrated Utilities & Services and core reducer tests to Vitest.
- Updated unit tests for multiple modules.

## [4.4.7] - 2026-01-23

### Added
- Unit, Smoke, and Regression Tests Created.
- Implemented SceneReducer regression shield and modernized test runner.
- Added verification and documentation for image similarity offloading, geocoding proxy, and cache implementation.
- Added unit tests for RequestQueue, SessionStore, SimulationLogic, SimulationDriver, NavigationController, UiReducer, and AppContext using Vitest.
- Implemented robust DMS (Degrees, Minutes, Seconds) coordinate parsing.
- Added hemisphere correction (N/S/E/W) for accurate GPS coordinates.
- Added comprehensive diagnostic logging for GPS extraction pipeline.
- Added accept-language=en to geocoding API for English addresses.

### Changed
- Updated unit tests for HotspotLine, ProjectManager, DownloadSystem, and NavigationRenderer.
- Perfected GEMINI.md & MAP.md.
- Implemented Code Sentinel automation and surgical brand renaming to Robust VTB.
- Enhanced EXIF tag discovery with case-insensitive matching.
- Parallelized EXIF extraction and image compression for 50% faster uploads.
- Enhanced Unicode support for international location names.
- Improved frontend/backend GPS data recovery with local fallback.

### Fixed
- Resolved upload progress hang on duplicate files and updated testing workflows.
- Fixed GPS extraction and geocoding for location-based project naming.
- Fixed project name replacement logic to recognize Tour_ patterns as placeholders.

### Security
- Eliminated innerHTML and dangerouslySetInnerHTML vulnerabilities.

## [4.4.6] - 2026-01-22

### Changed
- Reduced room label font size to 12px for better visual balance.

## [4.4.5] - 2026-01-22

### Changed
- Simulation Stable.
- UI Polish v2 Good.
- Maximum UI Polish v1.

## [4.4.2] - 2026-01-22

### Fixed
- Fixed synchronization gap where Service Worker was not updated during commits.

### Changed
- Updated commit-workflow.md to reflect package.json as single source of truth.
- Enhanced package.json version-sync script to include Service Worker synchronization.

## [4.4.1] - 2026-01-22

### Changed
- Updated Modal system to support custom classes.
- Applied solid header-blue (#0e2d52) background to New, About, and Upload Summary modals.

## [4.4.0] - 2026-01-22

### Changed
- UI Consistency and UX Polish.
- Updated Teaser button to match Export button styling.
- Updated Floor Navigation hover effects to match Sidebar buttons.
- Updated Viewer Utilities buttons to match header theme.

## [4.3.9] - 2026-01-22

### Changed
- Rebranded primary action colors to Super Orange (#ea580c).
- Updated all UI components to use the new orange-based danger/action palette.
- Refined Viewer stage background and UI layering for better contrast.
- Synchronized version 4.3.9 across all systems.

## [4.3.8] - 2026-01-21

### Fixed
- Final UI Polish: Standardized Tooltips, Fix Menu Cropping, and 3-dot Menu Visibility.
- Fixed Tooltip Z-Index, Label Menu Cropping, Scene Menu Visibility.
- Fixed UI Issues & Create Button Component.

### Changed
- Anchor-Based Positioning Refactor Complete.
- Perfected Docs & Stable App Before React Tweak.

## [4.3.7] - 2026-01-21

### Added
- Viewer Guard Checks.
- Added Retry Logic to AutoPilot.

### Changed
- Final AutoPilot Optimizations.
- Enabled Progressive Loading for AutoPilot.

### Fixed
- Removed console.log usage and fixed CSS build.
- Robust Stable UI No Ghost.
- Resolved ghost arrow artifact at (0,0) during scene transitions.
- Fixed Viewer Instance Race Condition.
- Fixed AutoPilot Timeout Mismatch.

## [4.3.6] - 2026-01-20

### Changed
- Refined project name input styling for premium aesthetic.
- Unified AutoPilot timeouts to prevent race conditions.
- Enabled progressive loading for AutoPilot previews.
- Implemented retry logic for AutoPilot scenes.

### Fixed
- Resolved Viewer Instance race condition during simulation.

## [4.3.5] - 2026-01-20

### Changed
- Refined sidebar typography and teaser button iconography.
- Added premium purple-brand color to design system.

## [4.3.4] - 2026-01-20

### Changed
- UI stabilization and sidebar UI enhancements.

## [4.3.3] - 2026-01-19

### Fixed
- Fixed hotspot full visibility and arrow delete button.
- Fixed sticky waypoint persistence and synchronization.
- Resolved scene switching guard and loading logic.

## [4.3.2] - 2026-01-18

### Added
- Implemented global RequestQueue to prevent 429 errors.
- Stable Add Link dynamics with momentum-based camera movement.

### Fixed
- Standardized logging and error handling.
- Fixed link dynamics and edge panning restrictions.

## [4.3.1] - 2026-01-17

### Fixed
- Restored linking mechanics (rod, director curve).
- Fixed Linking Mode visualization and hotpot line rendering.
- Enhanced Logger with error capturing.

## [4.3.0] - 2026-01-16

### Added
- Comprehensive unit tests for RootReducer, EventBus, ProjectReducer, and others.
- Implemented Secure Production Logging.
- Dynamic SEO and HTML configuration.

## [4.2.1] - 2026-01-13

### Changed
- Stable Release: Complete migration to ReScript v12 Core.
- Implemented single-ZIP project loading.
- Added backend validation system and checksum metadata.
- Ported backend API, Resizer, and ProjectManager module to ReScript.
