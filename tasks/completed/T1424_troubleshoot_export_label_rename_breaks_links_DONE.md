# T1424 - Troubleshoot Export Link Breakage After Scene Labeling

## Objective
Fix export navigation so hotspot links remain valid after labeling multiple scenes by using stable scene identifiers instead of mutable scene names.

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Export scene graph keys and hotspot targets are name-based; label edits rename filenames (`scene.name`) and create stale/mismatched targets.
- [x] **H2**: Runtime resolver complexity is compensating for mutable names and still failing on multi-rename projects.
- [x] **H3**: Canonical `scene.id` keys and target mapping at generation time will eliminate rename-induced link mismatch.

## Activity Log (Experiments / Edits)
- [x] Inspect export payload model in `src/systems/TourTemplates.res` (scene keying and hotspot target serialization).
- [x] Switch exported `scenesData/config.scenes` keys from `scene.name` to stable `scene.id`.
- [x] Add export-time target resolution from hotspot target-name -> target scene id.
- [x] Preserve filename (`scene.name`) only for panorama asset path.
- [x] Keep runtime fallback for legacy targets but prioritize canonical `targetSceneId`.
- [x] Verify with `npm run build`.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Export scene graph now keyed by stable `scene.id`; scene payload keeps `name` for asset resolution/display and hotspots now carry both legacy `target` and canonical `targetSceneId`. Added export-time resolver (`normalizeSceneRefForExport`, `extractScenePrefix`, `resolveSceneIdFromTargetRef`) and runtime target resolver preference for canonical ids. Revert path: restore name-keyed graph and legacy target-only payload.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Document why labels triggered failures and how id-keyed export resolves it.
- [x] Note any compatibility fallback kept for old/stale targets.
- [x] Record build verification status.
