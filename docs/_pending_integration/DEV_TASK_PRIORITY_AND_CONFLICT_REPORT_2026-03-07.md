# Dev Task Priority, Renumbering, and Conflict Report (2026-03-07)

## Scope
- Started and refreshed:
  - `D014` (historical review file annotated as reference-only)
  - `D015` (renumbered to `D001`, MAP tree update applied)
- Renumbered pending dev tasks by urgency and execution safety.
- Performed merge/split conflict audit and resolved discovered conflict in geocoding lane.

## Renumbering Map (Old -> New)
- `D015_Update_Map_Tree.md` -> `D001_Update_Map_Tree.md`
- `D004_Classify_Ambiguous_Files.md` -> `D002_Classify_Ambiguous_Files.md`
- `D018_Surgical_Refactor_API_BACKEND.md` -> `D003_Surgical_Refactor_API_BACKEND.md`
- `D019_Surgical_Refactor_PROJECT_BACKEND.md` -> `D004_Surgical_Refactor_PROJECT_BACKEND.md`
- `D012_Surgical_Refactor_CORE_FRONTEND.md` -> `D005_Surgical_Refactor_CORE_FRONTEND.md`
- `D016_Surgical_Refactor_TRAVERSAL_FRONTEND.md` -> `D006_Surgical_Refactor_TRAVERSAL_FRONTEND.md`
- `D017_Surgical_Refactor_SIDEBAR_FRONTEND.md` -> `D007_Surgical_Refactor_SIDEBAR_FRONTEND.md`
- `D011_Surgical_Refactor_COMPONENTS_FRONTEND.md` -> `D008_Surgical_Refactor_COMPONENTS_FRONTEND.md`
- `D005_Surgical_Refactor_EXPORTER_FRONTEND.md` -> `D009_Surgical_Refactor_EXPORTER_FRONTEND.md`
- `D006_Surgical_Refactor_UTILS_FRONTEND.md` -> `D010_Surgical_Refactor_UTILS_FRONTEND.md`
- `D007_Surgical_Refactor_SYSTEMS_FRONTEND.md` -> `D011_Surgical_Refactor_SYSTEMS_FRONTEND.md`
- `D008_Surgical_Refactor_GEOCODING_BACKEND.md` -> `D012_Surgical_Refactor_GEOCODING_BACKEND.md`
- `D009_Merge_Folders_BACKEND.md` -> `D013_Merge_Folders_BACKEND.md`
- `D014_v5.2.0_Logical_Review_Report.md` kept as `D014` (reference)

## Most Urgent Dev Tasks (Top 5)
1. `D002_Classify_Ambiguous_Files`
- Why urgent: Analyzer quality and all later recommendations depend on correct file taxonomy.

2. `D003_Surgical_Refactor_API_BACKEND`
- Why urgent: `backend/src/api/project.rs` is high-traffic and currently large; safest high-leverage backend split.

3. `D004_Surgical_Refactor_PROJECT_BACKEND`
- Why urgent: Packaging path is core publish path and should be decomposed early for maintainability.

4. `D005_Surgical_Refactor_CORE_FRONTEND`
- Why urgent: Decoder complexity affects load/save resilience and schema safety across app flows.

5. `D006_Surgical_Refactor_TRAVERSAL_FRONTEND`
- Why urgent: Traversal logic directly impacts simulation/teaser/export path consistency.

## Conflict Audit (Merge/Split)

### Conflict Found and Resolved
- Conflict pair: `D012` (split `backend/src/services/geocoding/cache.rs`) vs `D013` (merge `mod.rs` + `osm.rs` and originally delete folder).
- Issue: Deleting `backend/src/services/geocoding/` would invalidate `D012` target path.
- Resolution applied: Updated `D013` to be conflict-safe:
  - merge files inside same folder,
  - explicit guard not to delete folder while `cache.rs` exists,
  - sequencing note added.

### Remaining Risk Check
- No hard path collisions remain if tasks execute in this order:
  - Backend lane: `D003 -> D004`
  - Frontend lane A: `D005 -> D006 -> D007 -> D008`
  - Frontend lane B: `D009 -> D010 -> D011`
  - Geocoding lane: `D012 -> D013` (or run `D013` with folder-preservation guard)

## Execution Recommendation
- Start immediately with: `D002`, then `D003`, then `D004`.
- Keep geocoding tasks (`D012`, `D013`) in one lane and do not run them in parallel.
- Keep `D014` as informational reference only; do not schedule as implementation work.
