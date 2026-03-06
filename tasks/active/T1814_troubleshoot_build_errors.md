# T1814 Troubleshoot Build Errors

- Assignee: Codex
- Objective: Restore green production build (`npm run build`) without regressing current behavior.
- Boundary: `src/`, `backend/` only if compile requires; no feature expansion.

## Hypothesis (Ordered Expected Solutions)
- [ ] Invalid ReScript decoder type annotations in `ProjectApi.res` are causing compiler failure.
- [ ] Newly added API payload encoding uses an unsupported combinator (`Encode.null`) or mismatched JSON type.
- [ ] Secondary type mismatches from startup preload/snapshot wiring in `App.res` may fail after first fix.

## Activity Log
- [x] Run full build and capture exact errors.
- [x] Apply minimal code fixes.
- [x] Re-run build until clean.

## Code Change Ledger
- [x] `src/systems/Api/ProjectApi.res`: removed invalid `JsonCombinators.Json.Decode.decoder<...>` annotations; added explicit decode wrapper functions (`decodeDashboardProjects`, `decodeDashboardLoadResponse`, `decodeSnapshotSyncResponse`) for `handleJsonDecode` compatibility.
- [x] `src/systems/Api/ProjectApi.res`: replaced unsupported `Decode.json` with `Decode.id` for `projectData` payload.
- [x] `src/systems/Api/ProjectApi.res`: added local `castJson` external for cache cleanup response passthrough.
- [x] `src/App.res`: fixed optional snapshot argument call by branching `Some(id)` / `None` and calling `syncSnapshot` accordingly.
- [x] `src/App.res`: replaced invalid multi-statement `%raw` snippet with expression-safe one-liner to clear boot preload globals.

## Rollback Check
- [x] Confirmed CLEAN (all applied changes compile and build successfully).

## Context Handoff
Build is green again after API decoder and snapshot-call fixes. The route/page work and backend snapshot/dashboard code remains in-progress in working tree and should be validated functionally in dev mode. No rollback is needed for this troubleshooting slice.
