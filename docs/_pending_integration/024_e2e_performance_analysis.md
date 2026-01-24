# E2E Performance & Analysis Report

## Executive Summary
Implementation of E2E testing with Playwright revealed several integration challenges between the frontend and Rust backend in the test environment, primarily around file upload processing. While the test infrastructure is successfully set up and configured, the actual test execution exposed critical reliability issues in the upload pipeline that prevented full end-to-end verification.

## Test Environment Setup
- **Framework**: Playwright
- **Configuration**: Chromium, Firefox, WebKit
- **Fixtures**: Standardized WebP panorama images
- **Backend**: Actix-web (Rust)
- **Frontend**: ReScript / React

## Implementation Details
1. **Infrastructure**:
   - Created `tests/e2e` directory with critical user flow tests.
   - Configured `playwright.config.ts` to coordinate frontend/backend startup.
   - Established `tests/fixtures` for consistent test data.

2. **Test Coverage**:
   - `upload-scene.spec.ts`: Core upload and processing flow.
   - `create-link.spec.ts`: Hotspot creation and linking.
   - `scene-management.spec.ts`: Deletion and reordering.
   - `metadata-operations.spec.ts`: Category and floor level updates.
   - `production-features.spec.ts`: Export and teaser generation availability.
   - `viewer-navigation.spec.ts`: Virtual tour navigation.
   - `project-persistence.spec.ts`: Save/Load functionality.
   - `autopilot.spec.ts`: Automated tour simulation.
   - `accessibility.spec.ts`: Keyboard navigation verification.

## Analysis of Failures

### 1. Upload Pipeline Timeout
**Issue**: All tests dependent on scene upload failed with timeouts (15000ms+).
**Root Cause Investigation**:
- **Backend Health**: Confirmed backend is running and healthy (`curl /health` -> 200 OK).
- **Direct API Upload**:
  - `POST /api/upload` -> 404 Not Found (Expected, as this route doesn't exist in `main.rs`).
  - `POST /api/media/process-full` (Actual endpoint) -> 400 Bad Request with "Unsupported or invalid image format".
- **Format Mismatch**: The backend explicitly rejects images if it cannot detect the format.
  - `curl` upload of `154407_002.webp` resulted in format rejection.
  - The `process_image_full` handler uses `image::ImageReader::with_guessed_format()`.
  - It appears the specific WebP fixtures or the way they are being transferred in the test environment (or by curl) is causing format detection to fail on the backend.
- **Frontend Integration**: The frontend `ImageOptimizer` converts images to WebP via Canvas before sending. This client-side optimization might be failing silently or producing blobs that the backend doesn't recognize in the headless test environment.

### 2. Dependency Issues
**Issue**: Initial build failures in frontend due to missing `lib/utils` for Shadcn components.
**Resolution**: Created a polyfill `src/lib/utils.js` with `clsx` and `tailwind-merge` to allow compilation to proceed.

### 3. Connection Refused
**Issue**: Intermittent `ECONNREFUSED` errors during test startup.
**Analysis**: The `webServer` configuration in Playwright needs robust wait-on logic. The current setup attempts to start both, but race conditions occur if the backend takes longer to bind port 8080 than expected.

## Recommendations for Optimization

1. **Robust Backend Format Detection**:
   - Enhance `process_image_full` in `backend/src/api/media/image.rs` to fallback to file extension or content-type header if magic byte detection fails.
   - Add detailed logging for the first few bytes of uploaded files to diagnose "Unsupported format" errors.

2. **Frontend Error Handling**:
   - The frontend `UploadProcessor` catches errors but the UI notification might not be caught by Playwright if it disappears too quickly or doesn't render in the DOM structure expected.
   - Add data-testid attributes to critical status indicators (processing bars, error toasts) for more reliable testing.

3. **Test Stability**:
   - Mock the backend upload endpoint for frontend-only tests to verify UI logic without relying on the heavy image processing pipeline.
   - Use a dedicated "test mode" in the backend that bypasses heavy optimization (e.g., skips 4K resizing) to speed up E2E tests.

4. **CI Integration**:
   - The current setup requires running `cargo run` and `npm run dev` simultaneously. A unified `test:e2e` script that orchestrates this using `concurrently` or similar tools is recommended for CI.

## Conclusion
The E2E testing foundation is solid, but the application's core dependency on complex binary image processing makes "black box" testing fragile. The immediate next step should be debugging the specific image format rejection in the backend when running in the test/headless context.
