# Task 376: Refactor project.rs (Oversized)

## 🚨 Trigger
File `/Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project.rs` exceeds **700 lines** (Current: 707).

## Objective
Decompose `project.rs` into smaller, focused modules. Aim for < 400 lines per module.

## AI Prompt (Refactor Helper)
"Please analyze /Users/r2/Desktop/robust-virtual-tour-builder/backend/src/api/project.rs. It has 707 lines. Extract the core logic into new specialized modules (e.g. projectTypes.res, projectLogic.res) while keeping the main module as a lightweight facade."

## Execution Report
The `backend/src/api/project.rs` file has been decomposed into a directory module `backend/src/api/project/` containing specialized sub-modules:

1.  **`mod.rs`**: The facade that re-exports all public functions, ensuring backward compatibility for `main.rs`.
2.  **`export.rs`**: Contains `create_tour_package` logic for exporting tours.
3.  **`storage.rs`**: Contains `save_project`, `load_project`, and `import_project` for handling project persistence and sessions. This is the largest module but well within limits.
4.  **`validation.rs`**: Contains `validate_project` for checking ZIP integrity.
5.  **`navigation.rs`**: Contains `calculate_path` for tour navigation logic.

**Lines per module:**
- `mod.rs`: ~9 lines
- `export.rs`: ~95 lines
- `storage.rs`: ~320 lines
- `validation.rs`: ~45 lines
- `navigation.rs`: ~35 lines

**Verification:**
- `cargo check` passed successfully.
- API endpoints remain unchanged in `main.rs`.