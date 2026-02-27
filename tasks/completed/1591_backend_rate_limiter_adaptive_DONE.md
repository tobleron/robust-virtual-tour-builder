# Task: Adaptive Rate Limiting with Token Bucket Differentiation

## Objective
Upgrade the backend rate limiter from fixed-rate per-IP limiting to adaptive rate limiting with user-aware differentiation, endpoint-class burst allowances, and coordinated frontend backpressure.

## Problem Statement
The current `rate_limiter.rs` uses `actix-governor` with fixed per-second/burst settings per route class. All users share the same IP-based limits. A legitimate power user performing a large upload can trigger rate limits that block their own navigation requests. The `RateLimitResponseTransformer` returns structured 429 responses but the frontend `RequestQueue.handleRateLimit` applies a flat pause without differentiating which endpoint class was limited.

## Acceptance Criteria
- [x] Implement per-session rate tracking (using session cookie or `X-Session-ID` header) in addition to per-IP
- [x] Add endpoint-class burstiness configuration: `media_heavy` allows 3x burst with refill, `read` allows 5x burst
- [x] Add a "token reserve" for critical operations: navigation/health requests always pass (minimum guaranteed rate) even when other classes are throttled
- [x] Return `Retry-After` header with per-class granularity (not a flat value)
- [x] Frontend `RequestQueue` should respect per-class `Retry-After`: pause only the rate-limited class, not the entire queue  
- [x] Add `x-ratelimit-remaining` and `x-ratelimit-limit` response headers for all API responses
- [x] Log rate-limit events with session context for post-incident analysis

## Technical Notes
- **Files**: `backend/src/middleware/rate_limiter.rs`, `backend/src/startup.rs`, `src/utils/RequestQueue.res`
- **Pattern**: Dual-key token bucket (IP + session) with per-class configuration
- **Risk**: Medium — must ensure rate limiting doesn't accidentally block legitimate burst workloads
- **Measurement**: A single user uploading 100 images should not trigger rate limits on their own navigation requests
