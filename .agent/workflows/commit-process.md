---
description: Standard commit process for changes
---

# Commit Process Workflow

Follow these steps for **every** change implemented through the AI agent:

## 1. Determine Branch Target

**Default**: `develop` (unless user explicitly requests `main` or it's a critical bug fix)

- For all AI-assisted changes → `develop`
- For user-requested stable updates → `main`
- For critical security/bug fixes → `main` (user decides)

## 2. Update Version

**File**: `src/version.js`

- Increment version appropriately:
  - `develop` → `vX.Y.Z-beta`
  - `main` → `vX.Y.Z`
- Add 3-word description (e.g., `[Teaser Fix]`)
- Ensure `BUILD_INFO` is descriptive

**Example**:
```javascript
export const VERSION = 'v4.1.5-beta';
export const BUILD_INFO = '[Simulation Loop]';
```

## 3. Update Cache Busting

**File**: `index.html`

Update query parameters to match new version:
```html
<link rel="stylesheet" href="css/style.css?v=4.1.5-beta">
<script type="module" src="src/main.js?v=4.1.5-beta"></script>
```

**Critical**: Version string must match `src/version.js` exactly (including `-beta`)

## 4. Log Changes

**File**: `/logs/log_changes.txt`

Add entry at the top:
```
[2026-01-11 09:03] Version 4.1.5-beta
- Fixed infinite loop in simulation path generation
- Added waypoint validation checks
```

**Format**:
- Timestamp: `[YYYY-MM-DD HH:MM]`
- Version number
- Bullet points describing changes (user-facing language)

## 5. Run Security Review

Check if changes involve:
- User input handling
- File uploads
- URL/path construction
- Blob URL management
- External API calls

If yes, run: `/security-review`

## 6. Git Commit (Local Only)

Commit to local repository:

```bash
git add .
git commit -m "vX.Y.Z-beta [Brief Description]"
```

**Message format**: Must match version string and BUILD_INFO from `version.js`

**Example**: `git commit -m "v4.1.5-beta [Simulation Loop]"`

## 7. Verify

- [ ] `src/version.js` updated
- [ ] `index.html` cache busting updated
- [ ] `/logs/log_changes.txt` has new entry
- [ ] Git commit created locally
- [ ] No errors in console (if applicable)

## 8. DO NOT Push to GitHub

**Unless**:
- This is a major update (Y incremented in `vX.Y.Z`)
- User explicitly requests a push
- This is a critical security fix

If pushing is needed, run: `/pre-push-checklist`

---

**Note**: This process ensures all changes are properly versioned, logged, and committed locally without the time overhead of remote pushes on every change.
