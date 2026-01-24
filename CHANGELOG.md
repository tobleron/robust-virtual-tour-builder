# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Your new feature here.

### Changed
- Your change here.

### Fixed
- Your bug fix here.

### Security
- Your security fix here.

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
