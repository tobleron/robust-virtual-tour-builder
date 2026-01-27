# Task: 800 - Refactor: Playwright E2E Automation (Postponed)

## Objective
Implement a comprehensive End-to-End (E2E) testing suite using Playwright to verify high-level system interactions and prevent regressions in the complex navigation FSM.

## Technical Context
The application has strong unit test coverage, but its robustness depends on the interaction between multiple systems:
- UI State -> Action Dispatch -> FSM Change -> Viewer Command -> Asset Loading.
A Playwright suite is required to simulate a full user journey.

## Implementation Plan
1. **Environment Setup**: Define a Playwright configuration (`playwright.config.ts`) and ensure `npm install -D @playwright/test` is handled.
2. **Base Harness**:
   - Create a mock backend or use a test instance.
   - Implement helper methods for "Upload Tour," "Add Link," and "Run Simulation."
3. **Core Scenarios**:
   - **Upload Flow**: Test batch image upload and verification of the processing report.
   - **Navigation Integrity**: Verify that clicking a hotspot correctly triggers the `NavigationFSM` and loads the target scene.
   - **Simulation/Autopilot**: Assert that the autopilot correctly sequentializes scene movements without hang-ups.
4. **CI Integration**: Add `npm run test:e2e` to the project scripts.

## Verification Criteria
- [ ] Playwright suite runs locally.
- [ ] Initial smoke test for the main viewer loads successfully.
- [ ] Documentation updated in `docs/testing.md` (if exists).

## Related Modules
- `src/systems/NavigationFSM.res`
- `src/systems/UploadProcessor.res`
- `src/components/ViewerUI.res`
- `backend/src/main.rs` (for integration points)
