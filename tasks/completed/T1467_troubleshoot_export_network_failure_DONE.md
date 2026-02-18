# T1467 - Troubleshoot export error due to network failure

## Objective
Diagnose and fix export failures that occur after `UPLOAD_START` and are presented as network-related export errors.

## Scope
- Frontend export pipeline in `src/systems/Exporter.res`.
- Error classification and user-facing message mapping for network/upload failures.
- No unrelated UI/feature changes.

## Hypothesis (Ordered Expected Solutions)
- [x] H1: Network error classification is too broad and masks backend HTTP error payloads as generic network failures.
- [ ] H2: XHR upload failure handling lacks robust fallback extraction for non-JSON or empty responses from backend/proxy interruptions.
- [ ] H3: Retry path conditions incorrectly skip recoverable transient failures.
- [x] H4: Backend URL reachability or auth edge case is producing deterministic upload failure that is surfaced as network failure.

## Activity Log
- [x] Create troubleshooting task and collect forensic logs (`logs/error.log`, exporter traces, current code paths).
- [x] Reproduce/analyze failure path around `UPLOAD_START` -> `EXPORT_FAILED`.
- [x] Implement targeted fix in exporter failure classification/messaging/retry path.
- [x] Verify via `npm run build` and summarize observed behavior.

## Code Change Ledger
- [x] `src/systems/Exporter.res` - Added export backend precheck, stronger transport error classification, and actionable backend-unreachable messaging. Revert note: revert this file if export regressions appear outside network-failure handling.
- [ ] (Pending) `src/systems/...` - _TBD_ - revert note: revert only if directly tied to failed hypothesis.
- [x] (Forensic) backend health probe (`curl http://localhost:8080/api/health`) returns connection failure; export enters `UPLOAD_START` then fails in XHR network path.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
If this troubleshooting session is interrupted, continue from the `UPLOAD_START` to `EXPORT_FAILED` transition in exporter telemetry and inspect the final normalized error message payload. Confirm whether failures are true network transport errors vs backend status/body parsing failures. Keep changes constrained to export error handling and ensure no regressions in successful export flow.
