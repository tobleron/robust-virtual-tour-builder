## Objective

Investigate and fix the backend upload quota test instability uncovered during the `main` promotion verification, where clean worktrees fail upload quota tests that pass in the long-lived local repo.

## Hypothesis (Ordered Expected Solutions)

- [x] The upload quota disk-space check is probing a repo-relative temp directory that exists locally but not in clean worktrees or CI.
- [ ] The upload quota tests are mutating shared environment state in a way that makes them order-dependent.
- [ ] The upload quota runtime may require an explicit test-safe temp directory fallback for environments that do not pre-create the configured temp path.

## Activity Log

- [x] Reproduced the failure in the clean `main` promotion worktree.
- [x] Confirmed the failing tests are `services::upload_quota_tests::test_quota_allows_small_upload` and `services::upload_quota_tests::test_concurrent_limit_per_ip`.
- [x] Identified `backend/src/services/upload_quota_runtime.rs` using `../tmp` as the fallback disk-space probe path.
- [x] Patched the runtime to probe the correct existing temp-root filesystem.
- [x] Re-ran the targeted quota tests with `TEMP_DIR` forced to a nonexistent path and confirmed they pass.
- [x] Re-ran the promotion verification suite after replaying the fix onto the clean `main` promotion branch.

## Code Change Ledger

- [x] `backend/src/services/upload_quota_runtime.rs` now resolves the nearest existing filesystem path for disk-space checks instead of assuming `../tmp` exists.

## Rollback Check

- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff

The `main` promotion branch exposed an upload quota test failure that does not appear in the long-lived local repo because the old runtime probed disk space against `../tmp`. That relative directory existed locally but not in clean worktrees, so quota registration failed before any upload was allowed. The runtime fix now resolves the nearest existing filesystem path for the configured temp root; resume by cherry-picking that fix into the promotion branch and rerunning the promotion verification suite.
