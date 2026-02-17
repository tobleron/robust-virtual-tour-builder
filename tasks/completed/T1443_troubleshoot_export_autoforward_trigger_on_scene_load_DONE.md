# T1443 - Troubleshoot export auto-forward trigger on scene load

## Objective
Fix exported-tour behavior so when a loaded scene is marked auto-forward, it always executes its own full waypoint animation and then advances automatically, regardless of previous scene type.

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] H1 (Highest): Export runtime fallback incorrectly disables auto-forward when no non-return hotspot is found; should still auto-forward from a resolvable hotspot when scene is auto-forward.
  - [ ] H2: Auto-forward resolution depends on previous-scene context instead of loaded-scene state in one remaining branch.
  - [ ] H3: Scene hotspot selection for auto-forward uses brittle index assumptions causing missed auto-advance for some scene graphs.

- [ ] **Activity Log**
  - [ ] Inspect export runtime scene playback selector and auto-forward gating.
  - [ ] Patch playback target resolution for scene-level auto-forward guarantee.
  - [ ] Add/update regression tests in `tests/unit/TourTemplates_v.test.res`.
  - [ ] Verify with `npm run res:build`, targeted tests, and `npm run build`.

- [ ] **Code Change Ledger**
  - [ ] Pending

- [ ] **Rollback Check**
  - [ ] Pending (Confirmed CLEAN or REVERTED non-working changes).

- [ ] **Context Handoff**
  - [ ] If resumed: focus on `resolveScenePlaybackHotspot` and ensure `sceneData.isAutoForward` directly drives post-animation auto-advance. Confirm fallback path still picks a valid hotspot and does not require previous-scene auto-forward context. Validate with TourTemplates unit test and full build.
