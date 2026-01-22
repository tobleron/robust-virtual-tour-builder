# Task 014: Add Unit Tests for RequestQueue

## 🎯 Objective
Create a unit test file to verify the logic in `src/utils/RequestQueue.res` using the Vitest framework.

## 🛠 Technical Implementation
- Created `tests/unit/RequestQueue_v.test.res` to avoid module name shadowing.
- Implemented tests verifying:
  - Module accessibility and ability to schedule tasks.
  - Correct initialization of `maxConcurrent` constant.
  - Accessibility of `activeCount` internal state.
- Updated `TestRunner.res` to remove the old manual `RequestQueueTest.run()` call.
- Verified that the new test is automatically picked up by Vitest via the `**/*.test.bs.js` pattern.
- Confirmed that all frontend tests pass and the build is successful.

## 📝 Notes
- Ported logic from the pre-existing manual `RequestQueueTest.res` into a Vitest-compatible format.
- Removed the old `tests/unit/RequestQueueTest.res` file.