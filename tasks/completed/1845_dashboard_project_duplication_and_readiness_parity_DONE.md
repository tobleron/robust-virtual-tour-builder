Assignee: Codex
Capacity Class: B
Objective: Add dashboard project duplication and make dashboard-triggered project loads wait for the same readiness/progress pipeline as local project loads before editing is considered ready.
Boundary: src/site/, src/components/Sidebar/, src/systems/Api/, src/systems/ProjectSystem.res, backend/src/api/project*.rs, backend/src/services/project/, tests/unit/
Owned Interfaces: dashboard project action buttons, dashboard project API contract, builder project-load readiness behavior
No-Touch Zones: src/core/Reducer.res, src/core/State.res, export runtime/tour template logic
Independent Verification: `npm run build` passes and dashboard duplicate/load behaviors compile with frontend/backend contract parity.
Depends On: 1843

# 1845 Dashboard Project Duplication And Readiness Parity

Add a dashboard action that duplicates a saved project without cloning its historical snapshots. The duplicate should be created from the latest restorable project state only, receive its own project/session identity, and appear in the dashboard as an independent project.

Also remove the current disparity between dashboard/server project loading and local project loading in the builder. Dashboard-triggered loads must pass through the same progress + readiness pipeline used for local loads so the builder only becomes interactive once the project is materially ready for editing instead of exposing a half-ready laggy state.

Acceptance:
- Dashboard project rows expose a duplicate action.
- Duplicate project creation copies only the latest restorable state, not snapshot history.
- Duplicate result appears as a separate dashboard project with a new session/project identity.
- Dashboard-triggered load shows the same project-load progress/readiness semantics as the local load path.
- Builder interaction after dashboard load only resumes when the viewer/project readiness checks have passed.
- `npm run build` succeeds.

Implementation Notes:
- Added dashboard project duplication endpoint and UI action that clones only the current snapshot plus referenced assets into a fresh project/session id.
- Routed builder saved-project opens and boot-time dashboard project loads through the same Sidebar project-load lifecycle/readiness gate used by local project imports.
- Boot preloads now carry a label token so saved-project loads present a proper project-load phase/message instead of direct state injection.

Verification:
- `npx vitest run tests/unit/PageFramework.test.js`
- `cd backend && cargo test duplicate_project_data_assigns_new_session_and_copy_name`
- `cd backend && cargo test collect_referenced_project_files_includes_logo_and_scene_assets`
- `cd backend && cargo check`
- `npm run test:frontend`
- `npm run build`
