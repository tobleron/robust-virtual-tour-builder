# 1921_public_launch_readiness_repo_check

## Objective
Bring the repository into a clean, publicly promotable state for broker-facing outreach by reconciling pending docs/worktree leftovers and rerunning the full release verification surface.

## Scope
- Ship the pending README / developer guide split cleanly
- Resolve obvious public-facing documentation inconsistencies
- Remove or exclude local-only generated artifacts from the final repo state
- Run the full CI-equivalent verification surface before final push

## Verification
- `./scripts/guard-main-release.sh main`
- `npm test`
- `npm run build`
- `npm run budget:bundle`
- `npm run test:e2e:budgets`
- `npm run budget:runtime`

## Notes
- Preserve contact and donation details in `README.md`
- Keep the main README broker-facing and move contributor workflow details into `DEVELOPERS_README.md`
- Runtime budget harness was repaired during this pass:
  - budget Playwright mode now launches both backend and frontend instead of only the frontend
  - budget mode starts its own fresh server instead of reusing an arbitrary existing one
  - budget specs now use the current builder-shell readiness flow and checked-in fallback fixtures
