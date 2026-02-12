# [1356] Persistence + Recovery Durability Hardening

## Objective
Guarantee crash-safe, versioned persistence and deterministic recovery replay for long-running operations.

## Scope
1. Introduce explicit schema versioning/migration for persisted app state.
2. Harden OperationJournal replay semantics (idempotent completion/failure transitions).
3. Validate recovery prompt and retry workflow against true resumability.

## Target Files
- `src/utils/OperationJournal.res`
- `src/utils/RecoveryManager.res`
- `src/utils/PersistenceLayer.res`
- `src/core/JsonParsersDecoders.res`
- `src/core/JsonParsersEncoders.res`

## Verification
- `npm run build`
- simulate interrupted upload/save/export and verify replay correctness.

## Acceptance Criteria
- No duplicate side effects during recovery replay.
- Backward-compatible migration path validated.
- Recovery UX reflects accurate operation state.
