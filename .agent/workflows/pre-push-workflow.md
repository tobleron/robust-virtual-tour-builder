---
description: Environment sanitization and consistency checks before pushing to GitHub.
---

# Pre-Push Workflow (Sanitization)

This workflow ensures the remote repository remains clean, secure, and production-ready.

## 1. Automated Sanitization
**Command**: `./scripts/pre-push.sh`
This script checks for:
- **Large Files**: Identifies accidental binaries or massive assets (>1MB).
- **Production Settings**: Verifies `debugEnabledDefault` is `false` in `Constants.res`.
- **Test Artifacts**: Finds leftover `.zip` or `.webp` files in test directories.

## 2. Manual Integrity Checks
Automation cannot catch everything. Perform these final "System 2" checks:

### Environment & Secrets
- [ ] **No Secrets**: Double-check that no `.env` files or API keys have been accidentally staged (check `git status`).
- [ ] **Clean Logs**: Verify `logs/` only contains `log_changes.txt` and `.gitkeep`.

### State Consistency
- [ ] **Build Status**: Ensure your last `commit.sh` run was successful and all tests passed.
- [ ] **Map Sync**: Verify `MAP.md` is updated if you added/moved files.
- [ ] **README Sync**: Verify `README.md` reflects the current version and test status.

## 3. Final Push
Once sanitized:
```bash
git push origin <your-branch>
```
If you find and fix issues during this workflow, **always use `./scripts/commit.sh`** to commit the fixes, as it ensures versioning and documentation stay in sync.