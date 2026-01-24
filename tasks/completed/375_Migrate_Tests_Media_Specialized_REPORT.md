# Task 375: Migrate Media & Specialized Services Tests to Vitest - REPORT

## Objective
Migrate the following legacy unit tests to Vitest and ensure 100% coverage:
- `ImageOptimizerTest.res`
- `VideoEncoderTest.res`
- `AudioManagerTest.res`
- `ServerTeaserTest.res`

## Outcome
Successfully migrated all 4 targeted modules to Vitest. The migration includes comprehensive mocks for browser APIs (Web Audio, Canvas, DOM, FormData, Fetch) to ensure tests run reliably in the Node environment.

### technical Details
1. **Created Vitest Versions**:
   - `tests/unit/ImageOptimizer_v.test.res`: Mocks Canvas and Image APIs to verify resizing and WebP compression logic.
   - `tests/unit/VideoEncoder_v.test.res`: Mocks fetch and RequestQueue to verify transcoding flow and callback lifecycle.
   - `tests/unit/AudioManager_v.test.res`: Mocks AudioContext and HTMLAudio to verify initialization and click sound playback.
   - `tests/unit/ServerTeaser_v.test.res`: Mocks FormData and Fetch to verify correct payload construction for server-side generation.

2. **Legacy Cleanup**:
   - Commented out corresponding entries in `tests/TestRunner.res`.
   - Deleted legacy `.res` test files.
   - Verified that the legacy runner now executes 0 tasks before handing over to Vitest.

3. **Verification**:
   - Running `npm run res:build && npm run test:frontend` confirms all 4 new test files pass.
   - Total Vitest suite: 98 files (1 failure in unrelated `ModalContext`).

## Success Criteria
- [x] Create `_v.test.res` versions for each.
- [x] Use `Vitest` bindings and follow functional testing standards.
- [x] Remove/Comment out entries from `tests/TestRunner.res`.
- [x] Delete legacy `.res` files after migration.
- [x] Verify tests pass with `npm run test:frontend`.
