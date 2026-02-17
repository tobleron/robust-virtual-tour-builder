# Task: Revision of Save Project Process

## Objective
Perform a comprehensive revision and hardening of the "Save project" process to ensure data integrity, reliability, and proper error handling across the entire stack (Frontend to Backend).

## Acceptance Criteria
- [ ] **Frontend Logic Audit**: Review `ProjectManager.res` and `ProjectSystem.res` for logical consistency. Ensure explicit handling of `Option`/`Result` and adherence to ReScript v12 standards.
- [ ] **Reliability & Journaling**: Verify that `OperationJournal` integration in `ProjectManager.res` correctly tracks the "SaveProject" operation through all stages (Starting, Success, Failure, Cancellation).
- [ ] **Recovery Logic**: Validate that `recoverSaveProject` in `ProjectManager.res` can successfully reconstruct state and resume saving when the application restarts after a crash or Interruption.
- [ ] **Backend Hardening**: Audit `backend/src/api/project.rs` (especially `save_project`) for proper cleanup of temporary files (e.g., `zip_path`) in all error paths.
- [ ] **Serialization Check**: Confirm all project data is encoded using `JsonEncoders` (which uses `rescript-json-combinators`) to maintain CSP compliance and avoid runtime evaluation.
- [ ] **Exporter Parity**: Ensure that `Exporter.res` (production export) and `ProjectManager.res` (project save) use a consistent data structure for the `.vt.zip` metadata to avoid structural drift.
- [ ] **Error Reporting**: Verify that all failure modes (Network timeout, File System Access API rejection, Disk full) are logged via `Logger` and reported to the user with clear feedback.
- [ ] **Build Verification**: Run `npm run build` and ensure the project compiles with zero warnings.

## Technical Notes
- The "Save project" flow involves: `ProjectManager.res` -> `ProjectSystem.res` -> `BackendApi.importProject`.
- The backend `save_project` handler uses `project_logic::create_project_zip_sync` to package files.
- Persistence is primarily via ZIP archives, while transient recovery state is stored in `IndexedDB`.
- Key files:
  - `src/systems/ProjectManager.res`
  - `src/systems/ProjectSystem.res`
  - `src/systems/Exporter.res`
  - `src/core/JsonEncoders.res`
  - `backend/src/api/project.rs`
  - `backend/src/api/project_logic.rs`
