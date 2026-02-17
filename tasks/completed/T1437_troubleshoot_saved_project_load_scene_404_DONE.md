# Task: Troubleshoot saved-project load scene 404s after save/import

## Context
User reports intermittent 404s when loading scene assets after saving and reloading a project:
`/api/project/<session>/file/<scene>.webp` returns `404 Not Found` for some scenes, causing SceneLoader load errors and navigation aborts.

## Hypothesis (Ordered Expected Solutions)
- [x] **Highest probability**: Backend validator mutates legacy `scenes[]` (removes orphaned scenes), while frontend loads from `inventory + sceneOrder`; save ZIP then includes assets only for surviving `scenes[]`, causing missing files for inventory-only scenes.
- [x] Save packaging copies files by parsing `/file/` URLs from `scenes[]` only; if URL formats differ or are absent for some scenes, those files are skipped.
- [ ] Import extraction path normalization/sanitization omits some archived image files under edge path patterns.
- [ ] Session mismatch between `sessionId` and on-disk project folder causes valid URLs to resolve into wrong project directory.

## Activity Log
- [x] Collected runtime logs and identified 404 failing endpoint pattern.
- [x] Traced frontend URL rebuild path (`ProjectManagerUrl.rebuildSceneUrls`).
- [x] Traced save/import backend flow (`save_project` -> `create_project_zip_sync` -> `import_project` -> `extract_zip_to_project_dir`).
- [x] Traced validator mutation path (`validate_and_clean_project`) and frontend decoder behavior (`project` decoder prioritizing `inventory + sceneOrder`).
- [x] Implemented structural fix: package file references from both `scenes[]` and active `inventory` scene entries.
- [x] Added regression test for inventory-only scene file retention in `.vt.zip`.
- [x] Verified build/test gates: `cargo check`, targeted `cargo test`, and root `npm run build`.

## Code Change Ledger
- [x] `backend/src/api/project_logic.rs`: Added robust filename extraction helper (`/file/`, relative paths, direct names), scene reference collectors, and inventory-aware file collection for ZIP save.
  Revert note: revert this file to pre-fix state to restore old scenes-only packaging behavior (not recommended).
- [x] `backend/src/api/project_logic.rs`: Updated `create_project_zip_sync` to copy referenced files using merged references from legacy scenes + active inventory.
  Revert note: same as above.
- [x] `backend/src/api/project_logic.rs`: Added regression test `test_create_project_zip_sync_includes_inventory_active_scene_files`.
  Revert note: remove test only if test harness changes; keep for bug coverage.

## Rollback Check
- [x] Confirmed CLEAN: no non-working exploratory patches kept; only the validated inventory-aware packaging fix and regression test remain.

## Context Handoff
The 404s were caused by save-package asset drift: ZIP save used `scenes[]` references only, while load/render uses `inventory + sceneOrder`. When validator/legacy drift removed or desynced entries in `scenes[]`, some referenced images were not copied into `images/` in `.vt.zip`, causing `/api/project/<session>/file/<name>` 404 after import. The fix now collects referenced files from both `scenes[]` and active `inventory` entries, and a regression test locks this behavior.
