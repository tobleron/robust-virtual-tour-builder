# T1445 - Troubleshoot export auto-forward with direct scene route mechanism

## Objective
Implement a robust export auto-forward mechanism that does not depend on hotspot DOM handler readiness. Auto-forward should execute after the loaded scene animation and then navigate using precomputed scene-level target metadata.

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] H1 (Highest): DOM-bound hotspot callback dependency causes missed auto-forward; direct route navigation from scene metadata will eliminate timing race.
  - [ ] H2: Runtime hotspot target resolution can drift; precompute `autoForwardHotspotIndex` + `autoForwardTargetSceneId` at export generation for deterministic behavior.
  - [ ] H3: Current per-attempt hotspot element lookup can select wrong hotspot under render timing; route-based navigation removes selector ambiguity.

- [ ] **Activity Log**
  - [ ] Add precomputed auto-forward route fields into exported `sceneData`.
  - [ ] Update runtime playback selector to use route fields first.
  - [ ] Prioritize direct `navigateToNextScene` for auto-forward execution after animation.
  - [ ] Add tests and verify build.

- [ ] **Code Change Ledger**
  - [ ] Pending

- [ ] **Rollback Check**
  - [ ] Pending

- [ ] **Context Handoff**
  - [ ] If resumed: check `sceneData` encoding and runtime `resolveScenePlaybackHotspot`/`attemptAutoForwardNavigation` paths. Ensure auto-forward branch no longer requires DOM handler availability and only triggers post-animation.
