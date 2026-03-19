# T1887 Troubleshoot Dashboard Projects Load

## Hypothesis
- [ ] The dashboard projects API is returning an error because the authenticated session is missing or not being sent from the dashboard page.
- [ ] The dashboard projects endpoint is succeeding but the current dev account simply has no saved projects, so the UI is showing an empty state that looks like a load failure.
- [x] The dashboard fetch path is hitting the wrong backend surface or a missing builder route mount, so `/api/project/*` is falling through to the static fallback instead of the JSON API.
- [ ] A backend project dashboard query or serialization path is failing after the dev-login startup fix, preventing the projects list from loading.

## Activity Log
- [x] Trace the dashboard projects request path from the frontend dashboard page to the backend API.
- [x] Inspect the dashboard fetch implementation, backend route handlers, and any auth/session requirements.
- [x] Reproduce the failure with the backend running directly and identify the API response or error.
- [x] Determine whether this is a true loading failure or simply an empty dashboard because no projects exist for the dev account.
- [x] Confirmed `POST /api/auth/dev-login` still works and returns the dev JWT/token pair.
- [x] Confirmed `GET /api/auth/me` succeeds with the dev token.
- [x] Confirmed `GET /api/project/dashboard/projects` returns `404 Not Found` with `No such file or directory (os error 2)`.
- [x] Confirmed `POST /api/project/save` also returns `404 Not Found`, so the builder project route tree is not active on the current server surface.
- [x] Confirmed the dev account has existing project directories under `backend/data/storage/<dev-user-id>/...`, so this is not an empty-dashboard data case.
- [x] Confirmed the live builder backend was routing `/api/project/*` to the app default fallback instead of the project handler tree.
- [x] Confirmed the root cause is route registration order: the top-level `/api` scope was shadowing the project scope before it could match.

## Code Change Ledger
- [x] `backend/src/api/config_routes_project.rs`: converted the project API builder into a reusable `/project` scope so it can be nested inside the main `/api` scope.
- [x] `backend/src/api/config_routes.rs`: moved the project scope into the main `/api` route tree so `/api/project/*` is no longer swallowed by the generic `/api` scope.

## Rollback Check
- [x] Confirmed CLEAN: the route registration fix is compiled, authenticated dashboard requests return the expected project list, and no rollback is needed.

## Context Handoff
- The dev-account login works and the dashboard route is now mounted correctly.
- This was a route-registration bug, not a data problem; the authenticated dev user already had project folders on disk.
- The fix lives in the builder backend route tree, and the portal deployment path was left untouched.
