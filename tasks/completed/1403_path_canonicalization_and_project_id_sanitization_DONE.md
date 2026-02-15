# 1403: Security - Path Canonicalization and Project ID Sanitization

## Objective
Eliminate path traversal risk in project storage and file serving.

## Context
Project/session identifiers are used in filesystem paths without strict sanitization:
- `backend/src/api/project.rs` uses project id from uploaded `project.json` and request payloads.
- `backend/src/api/project_logic.rs` returns raw `id` from ZIP metadata.
- `backend/src/services/media/storage.rs` joins user and project path segments directly.

## Suggested Action Plan
- [ ] Introduce a validated `ProjectId` format (UUID-like or strict `[A-Za-z0-9_-]+`) and reject invalid ids.
- [ ] Sanitize and validate `session_id` and imported `project.id` before any filesystem operations.
- [ ] Canonicalize resolved paths and assert they remain under `data/storage/<user_id>/`.
- [ ] Add equivalent guardrails for file-serving routes using `project_id` path params.
- [ ] Return structured `400` errors for invalid ids; do not fall back silently.

## Verification
- [ ] Add backend tests for `../`, absolute paths, encoded traversal (`%2e%2e`), mixed separators, and long ids.
- [ ] Confirm all malicious test cases return `400` and never create/read files outside user root.
- [ ] `cd backend && cargo test` passes with new security tests.
