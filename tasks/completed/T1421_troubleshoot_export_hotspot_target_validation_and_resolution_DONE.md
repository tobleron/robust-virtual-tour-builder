# T1421 - Troubleshoot Export Hotspot Target Resolution/Validation Error

## Objective
Fix export hotspot navigation so clicking always resolves to a valid exported scene id and never triggers Pannellum error "No panorama image was specified".

## Hypotheses (Expected Solutions Ordered by Probability)
- [x] **H1 (Highest)**: Runtime target resolver accepts non-existent fallback targets and still calls `loadScene`, causing panorama-not-specified errors.
- [x] **H2**: Hotspot args can differ from canonical scene graph target data; resolution should derive from owner scene + hotspot index first.
- [x] **H3**: Scene id formatting mismatches (encoded/path/extension/case variants) are not normalized before lookup.

## Activity Log (Experiments / Edits)
- [x] Inspect current resolver and navigation call path in `src/systems/TourTemplates.res`.
- [x] Add canonical scene-id resolution against actual exported scene keys only.
- [x] Resolve from owner scene hotspot record first, then fallback args candidates.
- [x] Add normalization for encoded/path variants and case-insensitive/no-extension matching.
- [x] Ensure `loadScene` only executes with a verified existing scene id.
- [x] Verify with `npm run build`.

## Code Change Ledger (for Surgical Revert)
- [x] `src/systems/TourTemplates.res` - Replaced permissive fallback load behavior with canonical resolver set: `normalizeSceneId` (decode/path cleanup), `stripSceneExtension`, `getExportSceneIds`, `resolveExistingSceneId` (exact + case-insensitive + no-extension + basename matching), and `resolveTargetSceneId` preferring canonical owner-scene hotspot target. `navigateToNextScene` now loads only verified existing scene ids. Revert path: restore earlier resolver and permissive fallback loading branch.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes before completion move.

## Context Handoff
- [x] Record exact resolver logic and why previous fallback failed.
- [x] Document any unresolved export link edge-cases.
- [x] Record build verification status.
