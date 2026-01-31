# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Added
- Implement unified diagnostic logging system with real-time UI toggle and live telemetry

### Fixed
- Resolve widespread test failures and schema runtime errors; restore App and ViewerManager unit tests

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
