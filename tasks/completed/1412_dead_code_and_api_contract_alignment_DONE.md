# 1412: Dead Code Cleanup - API Contract Drift and Unused Paths

## Objective
Remove unused code paths and align stale API client contracts with active backend routes.

## Context
Audit indicates drift and unused surface area:
- `src/systems/Api/ProjectApi.res` contains `loadProject` and `validateProject` endpoint shapes that do not match current backend handlers in `backend/src/api/project.rs`.
- `src/systems/Api/ProjectApi.res` and `src/systems/Api/MediaApi.res` define `getAuthHeaders` helpers not used by call sites.
- `src/core/AppContext.res` legacy hooks (`useSceneState/useUiState/useSimState`) appear unused.
- `src/core/SceneCache.res` cleanup APIs (`removeKeyOnly/clearSnapshot/clearAll`) are not currently invoked.
- Backend contains multiple `#[allow(dead_code)]` sections that should be reviewed and minimized.

## Suggested Action Plan
- [ ] Build a dead-code inventory (frontend + backend) and classify each item: remove, wire, or keep with documented rationale.
- [ ] Align/replace stale API methods so client contracts mirror backend routes and payloads.
- [ ] Remove unused helpers/hooks after confirming no test/runtime usage.
- [ ] Reduce `#[allow(dead_code)]` scope to unavoidable test-only or compatibility-only sections.
- [ ] Update `MAP.md` and `DATA_FLOW.md` only for retained architecture after cleanup.

## Verification
- [ ] `rg` usage checks show no orphaned public methods in cleaned modules.
- [ ] All API calls exercised in tests map to existing backend routes.
- [ ] `npm run res:build` and `cd backend && cargo check` pass cleanly.
