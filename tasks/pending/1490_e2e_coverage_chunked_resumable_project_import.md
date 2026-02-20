# 1490 - E2E Coverage: Chunked Resumable Project Import Reliability

## Purpose
Add production-grade E2E coverage for the new chunked/resumable project import flow so regressions are detected before release.

## Why This Task Exists
Chunked import (`/api/project/import/init|chunk|status|complete|abort`) introduces multi-step behavior that is not sufficiently protected by E2E tests yet. We need deterministic test coverage for success, retry, resume, and failure paths.

## Scope
- Create new Playwright E2E suite for chunked project import behavior.
- Add reusable helpers for chunk-flow route interception, throttling simulation, interruption, and resume.
- Validate UX outcomes (progress, errors, recovery messaging) and final project load correctness.
- Keep tests deterministic and CI-safe.

## Out of Scope
- Backend implementation changes.
- Frontend feature refactors outside testability hooks.
- Full performance benchmarking.

## Target Test Files
- `tests/e2e/chunked-import.spec.ts` (new)
- `tests/e2e/e2e-helpers.ts` (extend as needed)
- Optional fixture generator helper under `tests/e2e/fixtures/` if required.

## Scenarios to Cover
1. **Happy Path Import**
- `init` returns chunk contract.
- All chunks upload.
- `complete` returns valid import payload.
- UI loads project and scene list without errors.

2. **Resume After Interruption**
- Upload interrupted mid-way (network drop or page refresh simulation).
- Client calls `status` and uploads only missing chunks.
- Import completes successfully without re-uploading already accepted chunks.

3. **Rate-Limit Backoff During Chunk Upload**
- Simulate `429` on one or more chunk requests.
- Verify retry/backoff behavior.
- Ensure flow resumes and completes when backend allows requests again.

4. **Abort Behavior**
- User cancellation triggers `abort` endpoint.
- Pending uploads stop.
- UI exits import state cleanly with actionable feedback.

5. **Session Expiry / Invalid Upload ID**
- Simulate expired/unknown upload session.
- Verify clear user-facing error and no stuck loading state.

6. **Metadata Mismatch on Complete**
- Simulate completion with inconsistent metadata response from backend.
- Verify robust error handling and no corrupted load.

## Robustness Requirements
- Avoid flaky timing assumptions; use explicit wait conditions.
- Isolate each scenario (no shared mutable state between tests).
- Prefer deterministic API stubs for CI and optional real-backend smoke gating.
- Include clear assertion messages for fast triage.

## Acceptance Criteria
- New E2E suite added and passing locally in deterministic mode.
- Tests verify chunk flow endpoints are called in expected sequence.
- Resume scenario proves partial state recovery (missing chunks only).
- Failure scenarios produce expected UI feedback and stable app state.
- Existing E2E suites remain unaffected.

## Verification Commands
- `npm run test:e2e -- tests/e2e/chunked-import.spec.ts`
- `npm run test:e2e` (full suite sanity check)

## Risks
- Flaky tests from race conditions in async UI updates.
- Over-mocking that misses real integration problems.

## Mitigations
- Centralize waiting helpers and endpoint assertions.
- Keep one smoke-style integration test path that exercises realistic sequence.
- Use stable fixtures and explicit teardown.
