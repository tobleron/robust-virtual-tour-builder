# 1404: Performance/Security - Export Pipeline Memory and Quota Hardening

## Objective
Prevent memory spikes and quota bypasses during large export/package operations.

## Context
Current export path is memory-heavy and quota coverage is incomplete:
- `backend/src/api/project_multipart.rs` reads all package files into memory (`Vec<u8>`).
- `backend/src/services/project/package.rs` builds output ZIP in memory and returns `Vec<u8>`.
- `backend/src/middleware.rs` quota checks do not include `/api/project/create-tour-package` and identify client by `realip_remote_addr` raw string.

## Suggested Action Plan
- [ ] Refactor package multipart parsing to stream files to temp storage instead of in-memory vectors.
- [ ] Refactor ZIP output to streaming response or temp-file-backed response.
- [ ] Include `/api/project/create-tour-package` in quota policy.
- [ ] Normalize client identity to IP-only (strip port) before quota/rate decisions.
- [ ] Add endpoint-specific limits/timeouts for expensive media/export handlers.

## Verification
- [ ] Run stress test with large scene set and confirm bounded RSS/memory profile.
- [ ] Verify quota/rate limits trigger for repeated export requests from same client.
- [ ] Confirm no regressions in export artifact integrity (4k/2k/hd outputs).
- [ ] `cd backend && cargo test` passes.
