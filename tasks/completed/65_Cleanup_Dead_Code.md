# Task 65: Clean Up Dead Code and Comments

**Status:** Pending  
**Priority:** LOW  
**Category:** Code Maintenance  
**Estimated Effort:** 30 minutes

---

## Objective

Remove commented-out dead code and unused imports to improve code clarity and reduce cognitive load for developers.

---

## Context

**Current State:**
The project has accumulated some commented code and unused artifacts during migration and refactoring:

1. **`backend/src/handlers.rs` lines 1152-1157:** Commented `LoadProjectResponse` struct
2. **Potential test artifacts:** `src/test_exn.bs.js` (if exists)
3. **Unused imports or bindings** from migration phases

**Why This Matters:**
- Commented code creates confusion (is it needed? deprecated? forgotten?)
- Dead files increase repository size
- Reduces mental overhead when reading code
- Improves grep/search results

---

## Requirements

### Functional Requirements
1. Remove all commented-out code blocks
2. Delete unused test artifacts
3. Remove unused imports/bindings
4. Verify no functionality is lost
5. Update related documentation if needed

### Technical Requirements
1. Use `git blame` to understand why code was commented
2. Search for references before deletion
3. Document removal in commit message
4. Keep `CHANGELOG` if significant

---

## Implementation Steps

### Step 1: Remove Commented Struct in `handlers.rs`

**Location:** `backend/src/handlers.rs` lines 1152-1157

**Current Code:**
```rust
// NOTE: LoadProjectResponse is no longer used - we now return ZIP directly
// Keeping for reference during transition period
// #[derive(Serialize)]
// #[serde(rename_all = "camelCase")]
// pub struct LoadProjectResponse {
//     pub session_id: String,
//     pub project_data: serde_json::Value,
// }
```

**Action:** Delete entire block

**Verification:**
```bash
cd backend/src
rg "LoadProjectResponse" --type rust
```
Expected: No results (struct not referenced anywhere)

**Commit Message:**
```
chore: Remove commented LoadProjectResponse struct

This struct was part of the old session-based project loading.
We now return ZIP files directly, making this obsolete.
Confirmed no references exist in codebase.
```

---

### Step 2: Check for Test Artifacts

**Search:**
```bash
find src -name "test_exn.*" -o -name "*_test.bs.js"
```

**If found:**
- Check if file is actually used in test suite
- If unused, delete

**Common test artifacts to check:**
- `src/test_exn.bs.js`
- `src/*_old.res`
- `src/*.backup`

---

### Step 3: Find Unused Imports

Use ReScript compiler warnings to find unused bindings:

```bash
npm run res:build 2>&1 | grep "Warning: unused"
```

For each warning:
1. Open file
2. Verify import is truly unused
3. Remove import statement
4. Recompile

**Example:**
```rescript
// ❌ Unused
open Belt.Array

// If Array functions aren't used, remove the open
```

---

### Step 4: Search for Commented Code Blocks

**Find commented code:**
```bash
rg "^\/\/ (?:TODO|FIXME|NOTE|OLD|DEPRECATED)" src/ backend/src/
```

**Review each:**
- If TODO is obsolete: remove
- If FIXME is no longer relevant: remove
- If NOTE explains removed code: remove
- If code is "just in case" but old: remove

**Rules:**
- Keep TODOs for planned features
- Keep FIXMEs for known bugs
- Remove explanatory comments about deleted code

---

### Step 5: Remove Unused CSS/Backup Files

**Search:**
```bash
find css -name "*.backup" -o -name "*_old.css"
find src -name "*.backup" -o -name "*.bak"
```

**If found:** Review and delete if confirmed unused

---

### Step 6: Clean Up Empty/Placeholder Comments

**Find:**
```bash
rg "^\/\/ ?$" src/
rg "^\/\*\s*\*\/$" src/
```

**Remove:**
- Empty comment lines (leave blank lines for readability)
- Placeholder comment blocks

---

### Step 7: Update Documentation

If any removed code was documented:

1. Check `README.md` for references
2. Check `docs/` folder for mentions
3. Update or remove stale documentation

---

## Testing Criteria

### Compilation Tests
1. ✅ `npm run res:build` passes with no errors
2. ✅ `cargo build --manifest-path backend/Cargo.toml` passes
3. ✅ No new warnings introduced

### Functionality Tests
1. ✅ All existing tests pass
2. ✅ App starts successfully
3. ✅ Core workflows function (upload, navigate, export)

### Code Review
1. ✅ No commented code blocks remain (except intentional examples)
2. ✅ No unused test files
3. ✅ No `.backup` or `_old` files

---

## Expected Impact

**Code Quality:**
- ✅ Clearer codebase (no ambiguity about commented code)
- ✅ Easier to read and maintain
- ✅ Better search results (no false positives from dead code)

**Repository Health:**
- ✅ Slightly smaller repo size
- ✅ Cleaner git history going forward
- ✅ Easier code reviews (less noise)

**Developer Experience:**
- ✅ Less cognitive load when reading code
- ✅ No confusion about "should I uncomment this?"
- ✅ Cleaner grep/search results

---

## Checklist

Dead code to review:

- [ ] `backend/src/handlers.rs` commented struct (lines 1152-1157)
- [ ] Search for `test_exn` artifacts
- [ ] Search for `.backup` files
- [ ] Search for `*_old.*` files
- [ ] Remove unused imports (compiler warnings)
- [ ] Remove empty placeholder comments
- [ ] Remove TODO/FIXME for completed items
- [ ] Update documentation if needed

---

## Dependencies

None - standalone cleanup

---

## Rollback Plan

If accidentally removed needed code:
1. Check git history: `git log -p -- path/to/file`
2. Restore specific lines: `git show <commit>:path/to/file`
3. Cherry-pick restoration

**Safety net:** All removed code is in git history

---

## Related Files

**To Review:**
- `backend/src/handlers.rs` (commented struct)
- `src/**/*.res` (unused imports)
- `css/**/*.css` (backup files)
- All documentation in `docs/`

**To Delete (if found):**
- `src/test_exn.bs.js`
- `*.backup` files
- `*_old.*` files

---

## Success Metrics

- ✅ `rg "^\/\/ NOTE.*no longer used" backend/src/` returns 0 results
- ✅ `find . -name "*.backup"` returns 0 results
- ✅ Compiler warnings about unused code reduced to 0
- ✅ All tests pass
- ✅ Codebase feels cleaner and easier to navigate

---

## Optional: Create Cleanup Script

For future use:

```bash
#!/bin/bash
# scripts/cleanup-dead-code.sh

echo "Searching for potential dead code..."

echo "\n1. Commented NOTE blocks:"
rg "^\/\/ NOTE:.*(?:no longer|obsolete|deprecated)" src/ backend/src/

echo "\n2. Backup files:"
find . -name "*.backup" -o -name "*_old.*" -o -name "*.bak"

echo "\n3. Empty comment blocks:"
rg "^\/\/ ?$" src/ backend/src/ | head -20

echo "\nReview and remove manually after verification."
```

Make executable:
```bash
chmod +x scripts/cleanup-dead-code.sh
```

---

## Documentation Update

After cleanup, update `CHANGELOG.md`:

```markdown
## [Unreleased]

### Removed
- Commented `LoadProjectResponse` struct (obsolete after ZIP migration)
- Unused test artifacts
- Empty placeholder comments
- [List any other significant removals]
```
