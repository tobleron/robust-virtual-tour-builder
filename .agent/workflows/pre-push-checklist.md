---
description: Cleanup checklist before pushing to GitHub
---

# Pre-Push Checklist

Run this workflow **before** pushing to GitHub (major updates only: when Y increments in `vX.Y.Z`).

## 1. Backend Cleanup

// turbo
Clean Rust build artifacts:
```bash
cd backend && cargo clean && cd ..
```

**Purpose**: Removes large `target/` directory (reduces upload size significantly)

## 2. Log Rotation

Clean non-essential logs:
```bash
# Clear telemetry log if it exists
> logs/telemetry.log

# Keep log_changes.txt but verify it's not bloated
wc -l logs/log_changes.txt
```

**Action**: If `log_changes.txt` > 1000 lines, consider archiving old entries

## 3. Test Artifacts Cleanup

Remove temporary test files:
```bash
# Remove test ZIPs if verification is complete
rm -f test/*.zip test/*.webp

# Keep test_images/ folder intact
```

## 4. Verify Git Status

Check what will be committed:
```bash
git status
git diff --stat
```

**Check for**:
- ❌ Large binaries (> 1MB) - should be in `.gitignore`
- ❌ `node_modules/` - should already be ignored
- ❌ `backend/target/` - should be gone after cargo clean
- ❌ Personal test files or credentials
- ✅ Only source code, docs, and essential config files

## 5. Verify Version Consistency

**Check**:
- [ ] `src/version.js` has correct version (e.g., `v4.10.0`)
- [ ] `index.html` cache busting matches (e.g., `?v=4.10.0`)
- [ ] Latest entry in `logs/log_changes.txt` matches version
- [ ] Git HEAD commit message matches version

Run quick check:
```bash
grep "VERSION" src/version.js
grep "v=" index.html
head -n 5 logs/log_changes.txt
git log -1 --oneline
```

All should show the **same version number**.

## 6. Security & Quality Check

Run: `/security-review` if any recent commits involved:
- User input handling
- File/upload processing
- Authentication/authorization
- External API calls

## 7. Final Build Test

Test that everything works:
```bash
npm run dev
```

**Visual verification**:
- Open http://localhost:9999
- Check version displayed in UI
- Perform basic smoke test (upload image, create link, etc.)
- Check browser console for errors

## 8. Push to GitHub

If all checks pass:

```bash
# Push to appropriate branch
git push origin develop  # or main for stable releases

# Push tags if this is a major release
git tag -a vX.Y.Z -m "Version X.Y.Z - [Description]"
git push origin --tags
```

## 9. Post-Push Verification

- [ ] Check GitHub repository - files uploaded correctly
- [ ] Verify repository size didn't increase excessively
- [ ] Ensure no secrets or credentials were pushed
- [ ] CI/CD pipeline passes (if configured)

---

## Emergency: Large File Accidentally Committed

If a large file (> 1MB) was committed:

```bash
# Remove from current commit
git rm --cached path/to/large-file
git commit --amend -m "vX.Y.Z [Description]"

# If already pushed, use git filter-repo
# (requires installation: brew install git-filter-repo)
git filter-repo --path path/to/large-file --invert-paths
git push origin --force
```

---

**Important**: Major updates = Y increments (e.g., `v4.9.9` → `v4.10.0`). For critical security fixes, push immediately regardless of version.
