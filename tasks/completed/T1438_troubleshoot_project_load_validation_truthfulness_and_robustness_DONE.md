# Task: Troubleshoot project-load validation truthfulness and robustness

## Context
User reports warning notifications on load (`broken links removed`, `orphaned scenes`) that appear inconsistent with actual scene graph and linking behavior.

## Hypothesis (Ordered Expected Solutions)
- [x] Validator uses name-only hotspot target matching and can misclassify valid ID-based links as broken.
- [x] Orphan detection uses scene names and can overcount when naming drift or mixed link representations are present.
- [x] Import/load path returns stale validationReport from saved project JSON instead of recomputing against extracted files.
- [x] Import path cleanup/normalization gaps reduce trust in load diagnostics.

## Activity Log
- [x] Confirmed warning emission path in frontend load flow.
- [x] Traced backend validation and orphan detection logic.
- [x] Implemented ID-aware hotspot target validation and ID-based orphan detection.
- [x] Recomputed validation report during import/load and now return fresh project data.
- [x] Added backend tests for validator truthfulness and ID-first link handling.
- [x] Verified frontend+backend build checks.

## Code Change Ledger
- [x] `backend/src/services/project/validate.rs`: Added ID-first link resolution (`targetSceneId` -> ID/name fallback), ID-based orphan detection, hotspot `targetSceneId` backfill, and normalized name matching.
  Revert note: reverting this file restores old name-only semantics and reintroduces false warning risk.
- [x] `backend/src/api/project.rs`: Hardened `import_project` by recomputing validation report against extracted files, persisting normalized `project.json`, and returning fresh validated `project_data`.
  Revert note: reverting this file returns stale saved `validationReport` behavior on import.
- [x] `backend/src/services/project/mod.rs`: Added regression tests for ID-based link retention and `targetSceneId` backfill from name-based hotspots.
  Revert note: keep tests unless validator contract intentionally changes.

## Rollback Check
- [x] Confirmed CLEAN: no non-working exploratory changes kept; only validated fixes and tests remain.

## Context Handoff
This task aligned load warnings with real graph state by making validator semantics consistent with runtime linking (ID-first). Import now recalculates validation against extracted files and returns/persists fresh validated project JSON, so warnings are current and trustworthy. The added tests lock behavior for ID-based links and hotspot ID backfill to prevent regression.
