# 1488 - Implementation: Balanced Rate-Limit Profile Execution

## Purpose
Apply the approved 'Balanced' rate-limit profile across backend and frontend systems to resolve project-load timeouts and ensure stable batch uploads.

## Scope
- [x] Create rationale documentation in `docs/RATE_LIMIT_POLICY_RATIONALE.md`.
- [x] Update backend `startup.rs` with the new burst/refill values for production.
- [ ] Verify Frontend `AuthenticatedClient` and `RequestQueue` integration with new headers.
- [ ] Add regression tests to ensure 100-scene load metadata requests pass the new `Read` budget.
- [ ] Add regression tests for 5x5 batch uploads under the new `Write` budget.

## Accepted Profile Values (Production)
| Scope | RPS | Burst |
| :--- | :--- | :--- |
| Health | 10 | 100 |
| Read | 5 | 50 |
| Write | 2 | 20 |
| Admin | 1 | 10 |

## Verification
- `npm run res:build`
- `cd backend && cargo test`
- Manual E2E load test of a large project.
