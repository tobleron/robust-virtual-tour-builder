# Task 1503: Centralized Interaction Lock Policy Matrix

## Objective
Replace ad hoc lock decisions with a centralized capability-based lock policy matrix so only conflicting features are blocked while preserving interactive fluidity.

## Hard Dependency Gate
- Requires Task `1502` complete first.
- Task `1504` MUST NOT start until this task is marked complete.

## Problem Statement
Locking behavior is currently distributed across app mode checks and component guards. This creates inconsistency and makes it hard to reason about what should be blocked for each active operation.

## Why This Matters
- Prevents over-locking (poor UX) and under-locking (race risk).
- Makes lock semantics auditable and maintainable.
- Enables predictable behavior under concurrent operations.

## In Scope
- `src/core/AppContext.res`
- `src/core/AppFSM.res` (only where lock semantics require updates)
- `src/components/SceneList.res`
- `src/components/Sidebar.res`
- `src/components/ViewerUI.res`
- `src/components/LockFeedback.res`
- `src/systems/OperationLifecycle.res` (selectors as needed)
- New shared policy module(s) in `src/core/` or `src/systems/`
- Tests for lock matrix behavior

## Out of Scope
- Final reliability certification and T1495 closure (Task `1504`).

## Required Implementation
1. Define explicit capability set (example: `CanNavigate`, `CanEditHotspots`, `CanUpload`, `CanExport`, `CanMutateProject`, `CanStartSimulation`).
2. Implement centralized policy evaluator using active operation context (`type`, `scope`, `phase`, status).
3. Replace scattered lock checks with policy queries.
4. Keep navigation interruptible where safe; hard-lock only integrity-critical paths.
5. Ensure overlay/feedback reflects hard-lock states only.

## Execution Plan
1. Introduce policy types + evaluator module.
2. Add typed selectors/hooks for capability checks.
3. Migrate SceneList/Sidebar and app-wide lock overlay usage.
4. Preserve current critical blocking semantics for project load/export.
5. Add tests for capability outcomes under representative operation mixes.

## Verification Matrix
- Navigation during ambient thumbnail generation remains responsive.
- Project load/export still block conflicting mutations.
- No full-screen lock overlay during ordinary scene navigation.
- Concurrent operation cases resolve deterministically.

## Acceptance Criteria
- [ ] Centralized lock policy module exists and is authoritative.
- [ ] UI lock decisions use capabilities, not scattered ad hoc checks.
- [ ] Hard locks apply only to integrity-critical operations.
- [ ] Over-locking during normal navigation is removed.
- [ ] Tests cover capability matrix behavior.

## Handoff Evidence Required
- Capability matrix table (operation/phase → allowed/blocked capabilities).
- Component migration list showing removed ad hoc lock checks.
- Verification run summary for concurrent operation scenarios.
