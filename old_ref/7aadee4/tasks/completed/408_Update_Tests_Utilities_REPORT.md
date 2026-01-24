# Task Report 408: Update Unit Tests for Utilities (src/utils)

## Objective
Update and verify unit tests for the following utility modules:
- `src/utils/ColorPalette.res`
- `src/utils/UrlUtils.res`
- `src/utils/ImageOptimizer.res`
- `src/utils/StateInspector.res`
- `src/utils/GeoUtils.res`

## Fulfillment
- **Verified Coverage**: All listed utility modules have corresponding test files in `tests/unit/`.
- **Expanded `StateInspector` Tests**: Significantly improved test coverage for `StateInspector_v.test.res` by adding tests for environment-dependent functions (`exposeToWindow`, `removeFromWindow`) and verifying state snapshots.
- **Verification**: Ran all utility tests using Vitest (after ReScript compilation), confirming all 31 tests across 5 files pass.
- **Build Pass**: Project builds successfully with `npm run build`.

## Technical Details
- Used `vi.spyOn` in `%raw` blocks within ReScript tests to mock `Constants` for testing environment-specific logic.
- Ensured proper ReScript imports for `%raw` blocks by including dummy references to the required modules.
- Verified that `window.store` is correctly attached/detached and that the state snapshot is accurate and frozen.
