# Report 71: Pathfinder Logic Hardening and Deduping

**Status:** Completed  
**Priority:** MEDIUM  
**Category:** Backend Code Quality  
**Estimated Effort:** 1.5 hours

---

## Objective (Completed)

Refactor `pathfinder.rs` to eliminate `.expect()` calls, deduplicate common navigation logic, and improve error propagation to the API layer.

---

## Context

**Current State:**
- `pathfinder.rs` contains logic for "walking" and "timeline" paths.
- Both implementation functions duplicate a complex while-loop for "Chain Skipping" (skipping transitions/auto-forward scenes).
- There is at least one `.expect()` call that could panic the server if project data is corrupt.

**Why This Matters:**
- **Robustness:** A production backend should return an error for bad data, not crash.
- **Maintainability:** Fixes to navigation logic (like how auto-forward scenes are handled) should only be applied in one place.

---

## Requirements

### Technical Requirements
1. Extract "Chain Skipping" logic into a helper function.
2. Replace `.expect()` with `Result`.
3. Ensure the `calculate_path` handler in the API layer properly reports these errors as `400 Bad Request`.

---

## Implementation Details

### Step 1: Extract Auto-Forward Chain Helper
Create a function (e.g., `follow_auto_forward_chain`) that handles the logic seen in lines 178-201 and 246-279.

### Step 2: Error Hardening
- Change return types from `Vec<Step>` to `Result<Vec<Step>, String>`.
- Replace `expect()` with `Ok(...)` or `?`.
- Update line 161 (the specific `.expect` found during analysis).

### Step 3: API Integration
Update `handlers.rs` (or its modular equivalent) to handle the `Result`:
```rust
let path = calculate_walk_path(scenes, skip_auto_forward)
    .map_err(|e| AppError::InternalError(e))?;
```

---

## Testing Criteria

### Correctness
- [ ] Backend compiles.
- [ ] Navigation in "Auto Pilot" mode still works correctly, skipping transition scenes as expected.
- [ ] Unit tests for `pathfinder.rs` (if any exist or are added) pass.

---

## Rollback Plan
- Git revert.

---

## Related Files
- `backend/src/pathfinder.rs`
- `backend/src/handlers.rs` (to update the caller)
