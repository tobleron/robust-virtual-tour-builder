# T1444 - Troubleshoot export auto-forward not triggering on loaded projects

## Objective
Diagnose and fix exported-tour behavior where entering an auto-forward-enabled scene does not auto-advance after animation.

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] H1 (Highest): Export payload for `scenesData[sceneId].isAutoForward` is false/missing for loaded projects (legacy or migration gap), so runtime never triggers auto-forward.
  - [ ] H2: Runtime target resolution for auto-forward fallback fails for some scene graph shapes, preventing post-animation navigation.
  - [ ] H3: Auto-forward scene selection source in export builder (`state.scenes` vs inventory hydration) is stale at export time.

- [ ] **Activity Log**
  - [ ] Trace save/load decode/encode for `scene.isAutoForward`.
  - [ ] Trace export call chain and source scene collection.
  - [ ] Add compatibility fallback so export infers auto-forward from scene hotspots when explicit field is missing/inconsistent.
  - [ ] Verify with compile/tests/build.

- [ ] **Code Change Ledger**
  - [ ] Pending

- [ ] **Rollback Check**
  - [ ] Pending

- [ ] **Context Handoff**
  - [ ] If resumed: inspect `JsonParsersDecoders.scene`, `ProjectSystem` hydration, and `TourTemplates.generateTourHTML` data assembly. Ensure loaded legacy projects still export auto-forward scene intent reliably.
