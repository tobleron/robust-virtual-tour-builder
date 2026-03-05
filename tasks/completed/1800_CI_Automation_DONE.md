# Task 1800: Infrastructure: Re-enable Automated CI & Merge Gates

## 🤖 Agent Metadata
- **Assignee**: Jules (AI Agent)
- **Capacity Class**: A
- **Objective**: Automate CI triggers for push/PR to prevent regressions from landing in main.
- **Boundary**: `.github/workflows/ci.yml`.
- **Owned Interfaces**: None.
- **No-Touch Zones**: All `src/` and `backend/` code.
- **Independent Verification**: 
  - [ ] GitHub Actions tab shows automated execution on next push.
  - [ ] PR verification is required for merges to `main`.
- **Depends On**: None

---

## 🛡️ Objective
Transition from manual `workflow_dispatch` CI to automated, blocking CI gates. This ensures that every contribution is verified against build, unit test, and bundle budget requirements before it can be merged.

---

## 🛠️ Execution Roadmap
1. **Trigger Configuration**: Update `ci.yml` to trigger on `push` and `pull_request` for `main` and `development`.
2. **Path Filtering**: (Optional) Add path filters to ensure CI only runs when relevant files change.
3. **Concurrency Control**: Add `concurrency` groups to cancel in-flight runs on the same branch.
4. **Validation**: Manually trigger a push to verify the automated start.

---

## ✅ Acceptance Criteria
- [ ] CI triggers automatically on push to `main`.
- [ ] CI triggers automatically on PR creation.
- [ ] Build, Test, and Budget steps are all executed.
- [ ] (Manual Step) Configure Branch Protection in GitHub UI to require `test (ubuntu-latest)` to pass.
