# Task 68: Backend Service Extraction: Project and Packaging

**Status:** Pending  
**Priority:** HIGH  
**Category:** Backend Refactoring  
**Estimated Effort:** 2-3 hours

---

## Objective

Extract project validation, tour packaging (ZIP generation), and project management logic from the handlers into a dedicated `ProjectService`.

---

## Context

**Current State:**
The logic for `validate_and_clean_project` is a massive function in `handlers.rs`. Similarly, `create_tour_package` manages complex file IO and ZIP compression directly in the handler.

**Why This Matters:**
- **Business Logic Isolation:** Project validation is the "brain" of the application; it should be isolated from HTTP concerns.
- **Safety:** Managing session directories and temp files is error-prone and should be handled by a single service to avoid path traversal or leak issues.

---

## Requirements

### Technical Requirements
1. Create `backend/src/services/project.rs`.
2. Extract project-related logic that relies on `serde_json` and `zip-rs`.
3. Improve type safety by replacing generic `serde_json::Value` with typed models where possible.

---

## Implementation Steps

### Step 1: Create Project Service
- Create `backend/src/services/project.rs`.

### Step 2: Extract Validation and Cleaning
Move `validate_and_clean_project` from `handlers.rs` to `services/project.rs`.
Ensure it returns a typed `(ProjectModel, ValidationReport)` rather than raw JSON if possible (or keep JSON but move the logic).

### Step 3: Extract Packaging Logic
Move the core logic of `create_tour_package` into the service. 
The service should take a list of files and a project JSON, and return a `Vec<u8>` (the ZIP content) or a path to the ZIP.

### Step 4: Refactor Handlers
Update the following handlers to use the service:
- `save_project`
- `load_project`
- `validate_project`
- `import_project`
- `create_tour_package`

---

## Testing Criteria

### Correctness
- [ ] Backend compiles.
- [ ] Save/Load project functionality works in the frontend.
- [ ] Validation report generates correctly for broken projects (e.g., missing images).
- [ ] Tour download generates a valid ZIP file.

---

## Rollback Plan
- Git revert the commit.

---

## Related Files
- `backend/src/handlers.rs`
- `backend/src/services/project.rs` (New)
