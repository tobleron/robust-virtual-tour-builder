# Task 1501: Navigation Operation Completion Decoupling from Cleanup Timer

## Objective
Decouple navigation operation completion semantics from asynchronous viewer cleanup timing so the UI reflects true scene-ready state instead of cleanup latency.

## Hard Dependency Gate
- This task is the first step in the sequence.
- Task `1502` MUST NOT start until this task is marked complete.

## Problem Statement
Current navigation completion is tied to cleanup timeout flow in `src/systems/Scene/SceneTransition.res` (500ms resource cleanup timer path). This keeps operation status in `Stabilizing` longer than necessary even when user-visible scene switching is already complete.

## Why This Matters
- Produces avoidable progress-bar exposure on fast scene switches.
- Distorts performance perception and telemetry.
- Couples UX state with non-critical resource cleanup.

## In Scope
- `src/systems/Scene/SceneTransition.res`
- `src/systems/Navigation/NavigationSupervisor.res`
- `src/systems/Navigation/NavigationController.res`
- `src/systems/SceneLoaderLogic.res`
- Related unit/e2e tests for navigation completion behavior

## Out of Scope
- Global progress visibility threshold logic (handled by Task `1502`).
- Global lock policy redesign (handled by Task `1503`).

## Required Implementation
1. Introduce explicit navigation completion point based on scene readiness, not cleanup timeout.
2. Keep viewer/resource cleanup asynchronous and non-blocking for operation terminal state.
3. Preserve stale-task protection: stale timers/events must never complete a new task.
4. Ensure cancellation/abort behavior remains deterministic.
5. Keep phase updates (`Loading`, `Swapping`, `Stabilizing`) accurate, but emit terminal completion as soon as scene is ready for interaction.

## Execution Plan
1. Audit current completion ownership across `NavigationSupervisor.complete` and `SceneTransition` callbacks.
2. Move terminal completion trigger to a state/event that represents interaction-ready scene.
3. Leave cleanup timer for resource destruction only.
4. Add/adjust safeguards for stale task IDs and tokens.
5. Add tests for:
- fast scene switch where completion should not wait on cleanup timer
- rapid interruption/cancel path
- stale timeout callback ignored behavior

## Verification Matrix
- Rapid scene click sequence (manual + e2e) with no stuck `Stabilizing` after scene becomes ready.
- No regression in race protections under repeated interruption.
- No regression in resource cleanup correctness.

## Acceptance Criteria
- [ ] Navigation operation completion no longer depends on 500ms cleanup timer.
- [ ] UI-visible scene readiness and operation terminal state are aligned.
- [ ] Stale cleanup callbacks cannot complete wrong task.
- [ ] Existing rapid-switching tests pass.
- [ ] Added tests cover readiness-vs-cleanup decoupling.

## Handoff Evidence Required
- Before/after timing evidence for navigation operation completion.
- Logs proving stale callback protection still holds.
- Test run summary (unit + targeted e2e).
