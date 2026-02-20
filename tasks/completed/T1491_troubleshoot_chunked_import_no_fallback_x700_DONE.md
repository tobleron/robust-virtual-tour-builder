# T1491 - Troubleshoot chunked import with legacy fallback removed (x700.zip)

## Objective
Remove legacy project-import fallback from frontend API flow and verify `artifacts/x700.zip` import behavior using chunked endpoints only.

## Hypothesis (Ordered Expected Solutions)
- [x] H1: Generic `Request failed` is caused by legacy fallback path engaging and hitting payload/quota constraints; removing fallback resolves this for large ZIPs.
- [x] H2: Chunk upload path works, but completion step fails due to timeout/retry semantics; chunk transfer itself remains healthy.
- [x] H3: Backend write-rate limits (`429`) on chunk bursts cause retries to exhaust; import fails even without fallback.

## Activity Log
- [x] Review frontend import flow (`ProjectApi`) and remove fallback branch.
- [x] Update/adjust tests impacted by fallback removal (if present).
- [x] Build frontend to validate compilation.
- [x] Start backend and run a real chunked import attempt for `artifacts/x700.zip`.
- [x] Capture outcome and error class (rate limit/quota/timeout/validation).

## Code Change Ledger
- [x] `src/systems/Api/ProjectApi.res` - removed fallback helper and legacy-init fallback behavior. Revert note: restore `shouldFallbackToLegacyImport` and `importProjectLegacy` branch if compatibility must return.

## Rollback Check
- [x] Confirmed CLEAN. No non-working exploratory code remains.

## Context Handoff
- [x] Legacy fallback from chunked import init failure was removed in frontend API flow, so large imports now stay chunk-only. Local verification against `artifacts/x700.zip` completed successfully: init `200`, 21/21 chunks accepted `200`, complete `200` with project payload returned. During troubleshooting, an old backend process on port `8080` initially masked route behavior; after replacing it with current code, chunk endpoints behaved correctly.
