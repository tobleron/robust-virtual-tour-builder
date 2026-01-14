# Task 60: Eliminate Remaining `.unwrap()` Calls in Backend

**Status:** Pending  
**Priority:** HIGH  
**Category:** Backend Stability  
**Estimated Effort:** 30 minutes

---

## Objective

Remove all remaining `.unwrap()` calls in the Rust backend to improve reliability and follow functional programming best practices. Replace with proper error handling using `Result` types.

---

## Context

**Current State:**
The backend has **3 instances** of `.unwrap()` calls that could cause panics in production:

1. **`backend/src/main.rs:59`** - Logger initialization
2. **`backend/src/pathfinder.rs:160`** - Scene index lookup in pathfinding
3. **`backend/src/pathfinder.rs:190`** - Scene index lookup in junction

**Why This Matters:**
- `.unwrap()` causes **panics** when the value is `None`
- Panics crash the entire backend process
- No recovery possible - requires restart
- Violates functional programming standards (should return errors, not panic)

**Best Practice:**
Use `.ok_or()`, `.ok_or_else()`, or `.expect()` with descriptive error messages.

---

## Requirements

### Functional Requirements
1. Identify all `.unwrap()` calls in backend
2. Replace with proper error handling
3. Add descriptive error messages
4. Maintain existing functionality
5. Follow project's `AppError` patterns

### Technical Requirements
1. Use `.ok_or()` or `.ok_or_else()` for `Option` unwrapping
2. Use `.expect()` with clear messages for "impossible" cases
3. Return `Result<T, AppError>` or `Result<T, String>` from functions
4. Add tracing logs for error cases
5. Test all error paths

---

## Implementation Steps

### Step 1: Fix `backend/src/main.rs:59`

**Current Code (line ~59):**
```rust
.unwrap();
```

**Context:** This is likely in the logger/tracing initialization.

**Find the exact line:**
```bash
cd backend/src
grep -n "\.unwrap()" main.rs
```

**Replace with:**
```rust
.expect("Failed to initialize tracing subscriber. Check log file permissions.");
```

**Rationale:** 
- Logger initialization is critical at startup
- If it fails, we want a clear panic message (not silent failure)
- `.expect()` is acceptable here because we can't log if logging fails
- Provides actionable error message for ops team

---

### Step 2: Fix `backend/src/pathfinder.rs:160`

**Current Code:**
```rust
let mut next_idx = find_scene_index(&scenes, &link.target).unwrap();
```

**Replace with:**
```rust
let mut next_idx = find_scene_index(&scenes, &link.target)
    .ok_or_else(|| format!(
        "Pathfinding error: Scene '{}' referenced in link not found",
        link.target
    ))?;
```

**Additional Logging:**
Add before the line:
```rust
tracing::debug!(
    module = "Pathfinder",
    from = start_id,
    to = end_id,
    current_hop = link.target,
    "PATHFIND_FOLLOWING_LINK"
);
```

**Rationale:**
- `find_scene_index` can legitimately return `None` if project data is corrupted
- Should return error to caller, not crash backend
- Error message helps identify which scene is missing
- Caller can handle error gracefully (return 404 to frontend)

---

### Step 3: Fix `backend/src/pathfinder.rs:190`

**Current Code:**
```rust
next_idx = find_scene_index(&scenes, &j_link.target).unwrap();
```

**Replace with:**
```rust
next_idx = find_scene_index(&scenes, &j_link.target)
    .ok_or_else(|| format!(
        "Pathfinding error: Junction scene '{}' not found",
        j_link.target
    ))?;
```

**Additional Logging:**
Add before the line:
```rust
tracing::debug!(
    module = "Pathfinder",
    junction_scene = j_link.target,
    "PATHFIND_FOLLOWING_JUNCTION"
);
```

**Rationale:**
- Same as Step 2 - junction link could reference non-existent scene
- Graceful error allows frontend to show user-friendly message
- Debug log helps trace pathfinding decisions

---

### Step 4: Verify No Other `.unwrap()` Calls

Run a comprehensive search:
```bash
cd backend/src
rg "\.unwrap\(\)" --type rust
```

**Expected Output:** No results (or only in test modules)

If any additional `.unwrap()` calls are found:
1. Analyze context
2. Replace with appropriate error handling
3. Document in this task

---

### Step 5: Update Function Signatures (if needed)

**Check if `find_path` function needs signature change:**

Current (likely):
```rust
pub fn find_path(
    scenes: &[Scene], 
    start_id: &str, 
    end_id: &str
) -> Vec<String>
```

**Update to:**
```rust
pub fn find_path(
    scenes: &[Scene], 
    start_id: &str, 
    end_id: &str
) -> Result<Vec<String>, String>
```

**Update caller in `backend/src/handlers.rs`:**

Find the pathfinding handler and update:
```rust
// Before
let path = pathfinder::find_path(&scenes, &start, &end);
Ok(HttpResponse::Ok().json(PathResponse { path }))

// After
let path = pathfinder::find_path(&scenes, &start, &end)
    .map_err(|e| AppError::InternalError(e))?;
Ok(HttpResponse::Ok().json(PathResponse { path }))
```

---

## Testing Criteria

### Unit Tests (add to `pathfinder.rs`)

```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_find_path_invalid_start() {
        let scenes = vec![/* valid scenes */];
        let result = find_path(&scenes, "nonexistent", "scene_1");
        assert!(result.is_err());
        assert!(result.unwrap_err().contains("not found"));
    }
    
    #[test]
    fn test_find_path_invalid_target() {
        let scenes = vec![/* valid scenes */];
        let result = find_path(&scenes, "scene_1", "nonexistent");
        assert!(result.is_err());
    }
    
    #[test]
    fn test_find_path_broken_link() {
        // Create scene with link to non-existent target
        let scenes = vec![
            Scene {
                id: "scene_1".to_string(),
                links: vec![Link { target: "ghost_scene".to_string() }],
                ..Default::default()
            }
        ];
        let result = find_path(&scenes, "scene_1", "scene_2");
        assert!(result.is_err());
    }
}
```

### Integration Tests

1. **Valid Pathfinding:**
   ```bash
   curl -X POST http://localhost:8080/pathfind \
     -H "Content-Type: application/json" \
     -d '{"start": "scene_1", "end": "scene_5"}'
   ```
   Expected: Returns path array

2. **Invalid Start Scene:**
   ```bash
   curl -X POST http://localhost:8080/pathfind \
     -H "Content-Type: application/json" \
     -d '{"start": "nonexistent", "end": "scene_5"}'
   ```
   Expected: Returns 500 with error message (not panic)

3. **Corrupted Project Data:**
   - Upload project with broken scene references
   - Attempt pathfinding
   - Expected: Error response, backend still running

### Manual Verification

1. Run backend with `RUST_BACKTRACE=1`
2. Trigger all error paths
3. Verify no panics occur
4. Check logs for error messages

---

## Expected Impact

**Stability:**
- ✅ Eliminates 3 potential crash points
- ✅ Backend becomes more resilient to corrupted data
- ✅ Errors return to frontend instead of crashing server

**Observability:**
- ✅ Clear error messages in logs
- ✅ Debug tracing shows pathfinding decisions
- ✅ Easier to diagnose issues

**Code Quality:**
- ✅ 100% compliance with functional programming standards
- ✅ Follows Rust idioms (`Result` propagation with `?`)
- ✅ Passes `clippy` lints

---

## Dependencies

None - this is a standalone refactor

---

## Rollback Plan

Changes are backwards compatible. If issues arise:
1. Git revert the commit
2. Backend functionality unchanged

---

## Related Files

- `backend/src/main.rs` (1 fix)
- `backend/src/pathfinder.rs` (2 fixes + tests)
- `backend/src/handlers.rs` (update caller if needed)

---

## Success Metrics

- ✅ `rg "\.unwrap\(\)"` in `backend/src` returns 0 results (excluding tests)
- ✅ All unit tests pass
- ✅ Integration tests pass for valid and invalid inputs
- ✅ No panics in error scenarios
- ✅ `cargo clippy` passes with no warnings
