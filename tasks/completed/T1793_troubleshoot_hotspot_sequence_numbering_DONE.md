# T1793 - Troubleshoot hotspot sequence numbering regression

## Objective
Investigate and fix the regression where only the first scene/hotspot shows a sequence badge after the recent return-node (`R`) sequencing implementation.

## Hypothesis (Ordered Expected Solutions)
- [ ] `HotspotSequence.buildSequenceMap` is producing entries only for the first move due to overly strict traversal guards or early termination.
- [ ] Return-node classification is incorrectly marking most forward links as `Return`, suppressing numeric badges in `ReactHotspotLayer`.
- [ ] Hotspot ID matching in `ReactHotspotLayer` fails for non-initial scenes (ID normalization mismatch between map keys and runtime hotspots).
- [ ] Sequence map generation is gated by simulation state/input assumptions that are not met on normal project load.

## Activity Log
- [x] Load task-required context and architecture docs (`MAP.md`, `DATA_FLOW.md`, `tasks/TASKS.md`).
- [x] Reproduce issue by tracing current sequence map outputs and hotspot render conditions.
- [x] Patch sequence classification logic to preserve numeric progression for forward traversal links.
- [x] Validate with unit tests and project build.

## Code Change Ledger
- [x] `tasks/active/T1793_troubleshoot_hotspot_sequence_numbering.md` - Created troubleshooting task artifact. Revert: remove file if troubleshooting is cancelled.
- [x] `src/systems/HotspotSequence.res` - Expanded forward-hotspot collection to include all non-return target links (not only traversal-tagged `Sequence` links), so numbering no longer collapses when traversal coverage is partial. Revert: restore the prior `Some(Sequence(_))` filter in `collectForwardHotspots`.
- [x] `src/components/LabelMenu.res` - Hid the visible Sequence tab entry from the scene label menu so sequence editing flow is stage-first via hotspot `#` modal. Revert: restore Sequence tab button in header.
- [x] `src/components/LinkModal.res` - Added sequence-order input and save-time reorder logic in retarget (`#`) modal, including positive-integer validation and no-edit messaging for return (`R`) links. Revert: remove `link-sequence-order` input block and reorder dispatch branch in retarget path.
- [x] `src/components/LinkModal.res` - Switched retarget sequence field from numeric spinner input to dropdown selector (`<select>`) and populated options from current forward-sequence cardinality for cleaner stage editing UX. Revert: restore numeric input control for `link-sequence-order`.
- [x] `src/systems/HotspotSequence.res` - Enforced parent-backlink override so hotspots targeting traversal parent scene are always marked `Return` (`R`) even when not explicitly traversed. Revert: remove the post-traversal parent-backlink pass.
- [x] `tests/unit/HotspotSequence_v.test.res` - Added regression coverage for disconnected/unreached scenes to ensure non-return hotspots still receive sequence numbers. Revert: remove the new test case if behavior is intentionally traversal-only.
- [x] `tests/unit/HotspotSequence_v.test.res` - Added regression test `marks parent-back links as R even when not traversed` to prevent return-link numbering regressions in hub/branch flows. Revert: remove this test if parent-backlink `R` behavior is intentionally changed.
- [x] `tests/unit/LinkModal_v.test.res` - Added retarget-modal sequence test to verify `Save Link` dispatches reorder metadata updates when sequence number changes from the hotspot `#` dialog. Revert: remove the new test block if this behavior is intentionally removed.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
This troubleshooting task targets a post-implementation regression in hotspot sequence badge rendering. The symptom is that only the first scene/hotspot displays numbering, while expected traversal badges are missing on subsequent transitions. Investigation will focus on `HotspotSequence` map generation, return-edge classification, and render-layer key matching so fixes remain isolated and reversible.
