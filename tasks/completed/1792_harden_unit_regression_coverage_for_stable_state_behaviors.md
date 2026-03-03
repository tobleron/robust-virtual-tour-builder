# 1792 Harden Unit Regression Coverage for Stable State Behaviors

## Objective
Capture the currently stable, working behavior of simulation/navigation/viewer-state coordination in deterministic unit tests so future refactors cannot silently reintroduce the previously fixed regressions (viewer not ready race, scene-transition completion timing drift, and simulation stall after first transition).

## Why This Task Exists
Recent fixes stabilized tour preview behavior in real usage and headed E2E validation, including:
- strict scene-aware viewer readiness gating,
- swap-finalization readiness barriers,
- scene-scoped simulation completion signaling,
- and resilient startup behavior under test orchestration.

These guarantees are currently validated mostly by integration/E2E behavior. They must now be represented at unit level (pure logic + reducer/FSM contracts) to prevent regressions from passing local refactor checks.

## Scope
- Frontend ReScript unit tests only (`tests/unit/*_v.test.res` and helper test modules).
- Add or expand unit tests for:
  - simulation advancement eligibility logic,
  - navigation FSM stabilization transitions,
  - scene readiness contract assumptions used by simulation decisions,
  - and stale/late completion-event handling semantics.
- Introduce small pure helper seams if needed to make behavior unit-testable without browser runtime.

## Explicit In-Scope Behaviors to Lock Down
1. Simulation must not advance when scene completion signal does not match current scene context.
2. Simulation must advance when completion signal matches current scene and FSM is idle.
3. First-scene behavior remains valid (no false blocking on initial scene).
4. Transition stabilization must not emit "ready to advance" semantics before readiness barrier is satisfied.
5. Retry/backoff pathways must preserve safety (no infinite loop, no premature stop on transient busy states).
6. Link traversal continuity: after first transition, subsequent transitions are still eligible when state is valid.

## Required Deliverables
- New/updated unit tests in relevant suites (Simulation, NavigationFSM, Scene transition helpers).
- Clear test names mapped to known regressions (e.g., "does_not_drop_scene_completion_signal_after_first_transition").
- Minimal pure helper extraction if required, with zero behavior change.
- Short mapping table in task notes: regression symptom -> unit test name.

### Mapping Table: Regression Symptom -> Unit Test Name
| Regression Symptom | Unit Test Name(s) |
| :--- | :--- |
| **Viewer not ready race** | `SimulationAdvancement > Transition Stabilization / Busy States > should WAIT if navigation state is not idle` AND `should WAIT if operation lifecycle is busy` |
| **Scene-transition completion timing drift** | `SimulationAdvancement > Scene Completion Signal Matching > should advance when completion signal matches current scene` AND `should NOT advance when completion signal does not match current scene` |
| **Simulation stall after first transition** | `SimulationAdvancement > First Scene Behavior > should advance immediately on first scene...` AND `SimulationAdvancement > Scene Completion Signal Matching > should advance when completion signal matches current scene` |
| **Texture loaded mismatch** | `NavigationFSM > TextureLoaded mismatch is ignored and stays in Preloading` |
| **Stale task completions** | `NavigationSupervisor > stale task operations are ignored` |

## Acceptance Criteria
- Unit tests reproduce and guard all listed in-scope behaviors.
- `npm run res:build` passes with zero warnings.
- `npm run test:frontend` passes.
- Tests are deterministic (no time-dependent flakes from real timers/canvas/runtime APIs).
- Existing behavior in current headed Cypress flow remains unchanged.

## Suggested Implementation Plan
1. Identify current logic points that contain scene-scoped advancement decisions.
2. Extract tiny pure predicates where direct unit coverage is currently hard.
3. Add focused unit tests for happy path and stale-signal path.
4. Add tests for first-scene and post-first-scene continuity.
5. Run compile + frontend tests.
6. Document symptom-to-test mapping in task file before archive.

## Non-Goals
- No visual/UI redesign.
- No new E2E framework migration.
- No backend logic changes.
- No broad architectural rewrite beyond testability seams.

## Verification Commands
```bash
npm run res:build
npm run test:frontend
```

## Risk Notes
- Avoid overfitting tests to implementation internals; anchor assertions on behavior contracts.
- Keep test data fixtures small and explicit to preserve readability.
