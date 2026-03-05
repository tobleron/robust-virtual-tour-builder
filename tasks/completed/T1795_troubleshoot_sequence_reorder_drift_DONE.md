# T1795 Troubleshoot Sequence Reorder Drift

- [x] **Hypothesis (Ordered Expected Solutions)**
  - [x] `deriveOrderedForwardRefs` manual insertion order causes unstable final ordering when many hotspots carry `sequenceOrder` metadata.
  - [x] Reorder updates are computed correctly, but display derivation reinterprets the same metadata into a different order on the next render.
  - [x] Legacy duplicate or sparse `sequenceOrder` values amplify the drift and produce apparent reversion.

- [x] **Activity Log**
  - [x] Inspected `LinkModal` save path (`buildReorderUpdates` + `UpdateHotspotMetadata` batch) and confirmed metadata updates are dispatched correctly.
  - [x] Identified instability in `HotspotSequence.deriveOrderedForwardRefs`: descending insertion into an empty/mixed list can re-shuffle manual sequence positions.
  - [x] Patched ordering derivation:
    - all-manual case: direct ascending manual sort
    - mixed case: ascending insertion by desired order with duplicate-position-safe tie handling
  - [x] Added 3+ hotspot all-manual regression test.
  - [x] Verified with `npm run res:build`, `npx vitest tests/unit/HotspotSequence_v.test.bs.js --run`, `npx vitest tests/unit/TourTemplates_v.test.bs.js --run`, and `npm run build`.

- [x] **Code Change Ledger**
  - [x] `src/systems/HotspotSequence.res`
    - Stabilized manual-order composition logic in `deriveOrderedForwardRefs` to prevent sequence drift after save.
  - [x] `tests/unit/HotspotSequence_v.test.res`
    - Added `keeps all-manual sequence ordering stable for 3+ hotspots` regression.

- [x] **Rollback Check**
  - [x] Confirmed CLEAN for this troubleshooting scope (no temporary debug edits left).

- [x] **Context Handoff**
  - [x] Sequence value drift was caused by ordering reconstruction, not by metadata dispatch persistence.
  - [x] Manual sequence ordering is now deterministic when all hotspots are manually ordered and remains stable in mixed auto/manual scenarios.
  - [x] Next verification should be interactive retarget/save in `#` dialog on `edge.zip` to confirm expected UX.
