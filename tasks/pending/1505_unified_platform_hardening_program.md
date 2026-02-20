# Task 1505: Unified Platform Hardening Program (Consolidated)

## Objective
Consolidate all remaining reliability/hardening work into one execution stream that covers:
- backend save/load/import protective hardening,
- rate-limit/backpressure hardening,
- chunked resumable import E2E reliability,
- malformed project handling UX.

This task supersedes fragmented hardening tasks and establishes one authoritative checklist.

## Superseded Tasks
- `tasks/postponed/1246_Handle_Malformed_Project_Files_Gracefully.md`
- `tasks/pending/1486_ai_execution_rate_limit_hardening_and_operationalization.md`
- `tasks/pending/1488_implementation_of_balanced_rate_limit_profile.md`
- `tasks/pending/1490_e2e_coverage_chunked_resumable_project_import.md`
- `tasks/pending/1492_backend_save_load_protective_hardening.md`

## Verification Note (from superseded 1490)
`1490` is not complete as specified:
- required file `tests/e2e/chunked-import.spec.ts` is missing.
- only partial chunked-import route stubs exist in `tests/e2e/race-certification.spec.ts`.

## Scope
### A) Backend Protective Hardening (Save/Load/Import)
1. ZIP bomb protections:
- decompressed-size limits,
- entry-count limits,
- bounded `project.json` parsing.
2. Multipart safety:
- bounded `project_data` field size in save path.
3. Concurrency safety:
- per-user/session save serialization lock.
4. Chunked import session controls:
- max active session cap per user.
5. Clear malformed-file diagnostics and safe failures.

### B) Rate-Limit + Backpressure Hardening
1. Route-class limiter verification and structured `429` contract.
2. Deterministic client retry precedence:
- `Retry-After` -> `x-ratelimit-after` -> payload `retryAfterSec` -> local fallback.
3. Adaptive queue pause/resume with anti-storm behavior.
4. UX taxonomy consistency:
- offline vs backend unavailable vs rate-limited countdown.
5. Throttle/recovery telemetry and operational counters.

### C) Chunked Import E2E Certification
Add dedicated deterministic suite:
- `tests/e2e/chunked-import.spec.ts`.

Required scenarios:
1. Happy path,
2. Resume after interruption,
3. 429 backoff during chunk upload,
4. Abort behavior,
5. Session expiry/invalid upload ID,
6. metadata mismatch on completion.

### D) Malformed Project Handling UX
1. Parse/load errors must present explicit actionable user notification.
2. No silent fallback to an empty project state without user-visible error context.
3. Ensure `error-recovery` coverage reflects current behavior.

## Execution Order (Mandatory)
1. Backend protective hardening foundations (A).
2. Rate-limit/backpressure hardening (B).
3. Chunked-import dedicated E2E suite (C).
4. Malformed-project UX hardening and final polish (D).
5. Final integrated validation.

## Acceptance Criteria
- [ ] Save/load/import paths enforce bounded resource usage and reject malformed payloads safely.
- [ ] Per-session concurrent save races are prevented deterministically.
- [ ] Rate-limit handling is structured, observable, and recovers without retry storms.
- [ ] Dedicated `chunked-import.spec.ts` exists and covers all required scenarios.
- [ ] Malformed project imports surface explicit errors and keep app stable.
- [ ] `npm run build` passes.
- [ ] `npm run test:frontend` passes.
- [ ] `cd backend && cargo test` passes.
- [ ] Targeted Playwright suites for chunked import and reliability pass.

## Deliverables
- Consolidated hardening code changes.
- Updated/added tests (unit + e2e).
- Verification evidence summary in `docs/_pending_integration/`.
- Clear residual-risk note (if any).
