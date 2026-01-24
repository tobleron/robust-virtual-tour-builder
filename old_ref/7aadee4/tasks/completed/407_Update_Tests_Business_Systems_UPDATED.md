# Task 407: Update Unit Tests for Business Systems (src/systems) - REPORT

## Objective
Update unit tests for specialized subsystems and domain logic in `src/systems` to ensure they reflect recent implementation changes and maintain high coverage.

## Fulfilled Requirements
- **ServerTeaser**: Added error handling tests for fetch failures and server errors.
- **ProjectData**: Added coverage for `toJSON` missing fields (`lastUsedCategory`, `exifReport`, `_metadataSource`).
- **UploadProcessorLogic**: Added tests for `fingerprintFiles` (including failure cases) and `processWithQueue` with concurrency and progress tracking.
- **AudioManager**: Improved assertions and state reset handling in unit tests.
- **SimulationDriver**: Added basic rendering tests with mocked state provider to ensure component safety.
- **NavigationController**: Added rendering tests with mocked state provider for `Navigating` state.
- **Verified Existing Tests**: Confirmed `NavigationUI`, `Exporter`, `HotspotLineLogic`, and `TourTemplateStyles` already had adequate coverage for recent changes.

## Technical Realization
- Updated ReScript test files in `tests/unit/` using `rescript-vitest`.
- Mocked global browser APIs (fetch, WebAudio) and project-specific contexts (`AppContext`).
- Fixed several syntax and type issues in test code during compilation (Option unwrapping, JSON encoding).
- Verified with `npm run res:build` and `npx vitest run`.
- Total test count increased from 39 to 46.
