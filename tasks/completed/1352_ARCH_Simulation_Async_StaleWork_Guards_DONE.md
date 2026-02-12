# [1352] Simulation Async Stale-Work Guards

## Objective
Harden simulation tick/advance lifecycle so delayed operations cannot corrupt current run state.

## Scope
1. Introduce simulation run-token checks around delayed tick and wait/retry paths.
2. Ensure simulation advance logic remains idempotent during navigation busy/idle transitions.
3. Remove stale mutable-ref edge cases that cause duplicated or skipped steps.

## Target Files
- `src/systems/Simulation.res`
- `src/systems/Simulation/SimulationNavigation.res`
- `src/systems/SimulationLogic.res`

## Verification
- `npm run res:build`
- simulation-focused unit/e2e runs for long chains and interruption recovery.

## Acceptance Criteria
- No stuck simulation after rapid navigation interaction.
- No double-advance on delayed callbacks.
- Simulation stop/resume behavior remains deterministic.
