# [1351] SceneLoader/Transition Idempotence Hardening

## Objective
Make scene loading and crossfade transition completion idempotent and stale-safe under rapid interaction.

## Scope
1. Bind scene loader safety timeout and viewer event callbacks to active navigation run-token.
2. Refactor `SceneTransition` split timers into a single lifecycle-owned finalize path.
3. Prevent duplicate cleanup and duplicate `NavigationSupervisor.complete` signals.

## Target Files
- `src/systems/Scene/SceneLoader.res`
- `src/systems/Scene/SceneTransition.res`
- `src/systems/Scene.res`

## Verification
- `npm run res:build`
- stress tests: rapid scene switching + mid-load aborts.

## Acceptance Criteria
- No duplicate completion/cleanup under repeated interrupts.
- Stale timeout/event callbacks are ignored.
- Crossfade completes or aborts with explicit final state.
