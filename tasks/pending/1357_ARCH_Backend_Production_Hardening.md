# [1357] Backend Production Hardening (Security + Resilience)

## Objective
Align backend runtime behavior with enterprise production standards for security and operational resilience.

## Scope
1. Harden environment-aware defaults (session keys, CORS, rate limits, timeouts).
2. Validate middleware correctness under error and high-load scenarios (quota + request tracking + shutdown).
3. Standardize safe temp/path handling and error responses.

## Target Files
- `backend/src/main.rs`
- `backend/src/startup.rs`
- `backend/src/middleware.rs`
- `backend/src/services/upload_quota.rs`
- `backend/src/services/shutdown.rs`
- `backend/src/api/utils.rs`

## Verification
- `cd backend && cargo test`
- `cd backend && cargo build --release`
- load/failure scenario checks for quota and graceful shutdown.

## Acceptance Criteria
- Safe-by-default production configuration (no permissive fallback).
- Middleware behavior remains correct when service calls fail.
- Graceful shutdown drains in-flight requests within configured timeout.
