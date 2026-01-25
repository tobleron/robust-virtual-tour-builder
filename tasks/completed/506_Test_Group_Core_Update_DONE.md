# Task 506: Update Unit Tests for Core Modules (DONE)

## 🚨 Trigger
Multiple core module implementation files are newer than their tests.

## Objective
Update the corresponding unit tests for the following core modules to ensuring they cover recent changes and maintain 100% code coverage.

## Sub-Tasks
- [x] **UploadProcessorTypes** (`src/systems/UploadProcessorTypes.res`) - Verified.
- [x] **SharedTypes** (`src/core/SharedTypes.res`) - Verified.
- [x] **EventBus** (`src/systems/EventBus.res`) - Verified.
- [x] **AppContext** (`src/core/AppContext.res`) - Verified.
- [x] **ServiceWorkerMain** (`src/ServiceWorkerMain.res`) - Verified.
- [x] **ViewerTypes** (`src/components/ViewerTypes.res`) - Verified.
- [x] **Resizer** (`src/systems/Resizer.res`) - Added test for `getChecksum` with crypto mock.
- [x] **AudioManager** (`src/systems/AudioManager.res`) - Verified.

## Implementation Details
- Updated `tests/unit/Resizer_v.test.res` to include a test for the new `getChecksum` function, utilizing a `crypto.subtle` mock via `Object.defineProperty` for compatibility with JSDOM/Node environment.
- Verified all core module tests pass.
- Verified build passes.

## Verification
- `npm run test:frontend` passed (subset of core module tests).
- `npm run build` passed.
