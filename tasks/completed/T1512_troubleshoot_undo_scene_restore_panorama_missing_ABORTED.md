# T1512 - Troubleshoot Undo Restore Causing Missing Panorama on Scene Switch

## Objective
Fix runtime scene switch failures after using scene delete/clear-links undo flow where SceneLoader logs `LOAD_ERROR` and Pannellum reports `No panorama image was specified.`.

## Hypothesis (Ordered Expected Solutions)
- [ ] Undo rollback can restore scenes with empty `file` URL; sanitize restored state by repairing `scene.file` from current state or fallback fields.
- [ ] SceneLoader currently assumes every scene has a valid primary panorama; add fallback resolution (`file -> originalFile -> tinyFile`) and prevent empty panorama payloads.
- [ ] Undo restores full app state including transient runtime slices; ensure restoration keeps structural data coherent for post-simulation navigation.

## Activity Log
- [ ] Trace undo handlers and snapshot rollback path.
- [ ] Add scene file repair during undo restore.
- [ ] Add SceneLoader fallback panorama resolver and guard logging.
- [ ] Validate with simulation + scene switching scenario.

## Code Change Ledger
- [ ] (pending) task scaffold added.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
The new undo flow captures and restores full state snapshots for delete/clear-links operations and may restore scene entries whose primary file reference is empty. Scene loading currently expects a non-empty panorama URL and fails hard when missing, which surfaces after simulation when switching scenes. The fix strategy is to harden both undo restore (repair scene file fields) and scene loading (fallback panorama selection) so navigation remains reliable.
