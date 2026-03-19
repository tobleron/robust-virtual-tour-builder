Assignee: Codex
Capacity Class: B
Objective: Add a shared signed-in shell with builder navigation, in-builder reopen flow, and rolling backend snapshot history for saved tours.
Boundary: src/index.js, src/site/, src/App.res, src/systems/Api/, src/systems/ProjectSystem.res, backend/src/api/project.rs, backend/src/startup.rs, tests/unit/, tests/e2e/
Owned Interfaces: builder/page shell rendering, project dashboard list/load APIs, snapshot history APIs, frontend project snapshot client types
No-Touch Zones: src/core/Reducer.res, src/core/State.res, backend auth token semantics
Independent Verification: `npm run build` passes and the builder/dashboard shell plus snapshot endpoints compile end-to-end.
Depends On: 1813

# 1816 Builder Shell Project Reopen and Snapshot History

Implement a unified signed-in experience across the framework pages and builder. The builder must expose clear navigation back to dashboard/account, display the current signed-in user in the top-right area, and offer an in-builder "Open Tour" flow using the user's saved projects.

Extend backend project snapshot persistence from a single canonical file to rolling retained history suitable for enterprise recovery. Keep `sessionId` as the project identity, retain up to 9 snapshots per project, expose history and restore APIs, and preserve latest-project loading behavior for dashboard and builder reopen flows.

Acceptance:
- Signed-in user identity appears on dashboard/account and builder.
- Builder includes explicit navigation back to dashboard and an in-builder tour picker.
- Existing dashboard project load flow still works.
- Backend keeps latest snapshot plus rolling retained history capped at 9 per project.
- Snapshot history can be listed and restored through typed frontend/backend interfaces.
- `npm run build` succeeds.
