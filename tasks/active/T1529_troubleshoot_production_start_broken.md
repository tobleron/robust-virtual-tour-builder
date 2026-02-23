# T1529 - Troubleshoot production start broken

## Hypothesis (Ordered Expected Solutions)
- [ ] Startup script succeeds but backend is not ready yet when frontend is used (readiness gap).
- [ ] Backend release startup fails due to port conflict (AddrInUse on 8080).
- [ ] Startup script fails because required runtime dependency (`serve`) is unavailable.
- [ ] Branch auto-switch with dirty tree causes inconsistent runtime assets.

## Activity Log
- [ ] Reproduce with `npm run start` from non-main branch.
- [ ] Capture exact error output for frontend and backend processes.
- [ ] Verify process list and listening ports (`3000`, `8080`).
- [ ] Validate backend health endpoint once running.
- [ ] Implement targeted fix and re-verify.

## Code Change Ledger
- [ ] (pending)

## Rollback Check
- [ ] (pending)

## Context Handoff
Production start was recently changed to auto-switch to `main`, build frontend, serve `dist`, and run backend with `cargo run --release`. User reports that production is still broken in real usage. Need exact runtime failure signature (port conflict/readiness/dependency) and then patch startup orchestration with readiness guards and clearer failure handling.
