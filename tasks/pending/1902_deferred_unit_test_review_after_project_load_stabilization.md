# 1902 Deferred Unit Test Review After Project Load Stabilization

## Purpose
This is the shared pending task for deferred unit-test review while the project-load gating and dashboard boot behavior are still being calibrated. Reuse this task for additional source changes in the same stabilization area instead of patching tests on every iteration.

## Reuse Rule
- Do not create another deferred test-review task for the same project-load stabilization campaign.
- Append newly changed source files/modules to the checklist below as work continues.
- Execute this task only after the dashboard-open and sidebar-load behavior is confirmed stable enough that test updates will not churn again.

## Current Deferred Review Targets
- [ ] [src/components/Sidebar/SidebarProjectLoadFlow.res](src/components/Sidebar/SidebarProjectLoadFlow.res): verify saved-project progress visibility and finalization behavior against the stabilized load gate.
- [ ] [src/components/Sidebar/SidebarProjectLoadLifecycle.res](src/components/Sidebar/SidebarProjectLoadLifecycle.res): align warning/success completion tests with the stronger readiness contract and timeout wording.
- [ ] [src/components/Sidebar/SidebarProjectLoadReadiness.res](src/components/Sidebar/SidebarProjectLoadReadiness.res): add focused readiness/stability tests for viewer-ready polling, long-task quiet windows, and stable-frame unlock conditions.
- [ ] [src/site/PageFrameworkBuilder.js](src/site/PageFrameworkBuilder.js): cover boot-overlay state transitions for dashboard-triggered builder opens.
- [ ] [src/index.js](src/index.js): cover dashboard preload boot-state setup and failure cleanup paths.
- [ ] [src/AppEffects.res](src/AppEffects.res): verify boot-state clearing after saved-project load success and failure.
- [ ] [src/Main.res](src/Main.res): verify boot-pending saved-project starts from clean initial state rather than restored session state.

## Execution Notes
- Prefer extending existing relevant suites before creating new test files.
- Use build/manual verification as the primary short-cycle check until the load behavior is accepted by the user.
- If any of the source files above change again before this task is executed, update this task instead of rewriting tests immediately unless explicit test work is requested.

## Verification When Executed
- `npm run test:frontend`
- any narrower targeted suite for sidebar/project-load modules

## Exit Criteria
- The files above have aligned automated coverage for the final accepted load-gating behavior, or are explicitly documented as intentionally relying on build/manual verification only.
- The test expectations match the final user-approved dashboard-open and sidebar-load experience.
