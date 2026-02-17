# T1446 - Troubleshoot export auto-forward by double-chevron scene rule

## Objective
Ensure exported tours auto-advance based on the scene's own double-chevron hotspot rule: if entered scene contains an auto-forward hotspot (double-chevron), run full animation then auto-advance to that hotspot target.

- [ ] **Hypothesis (Ordered Expected Solutions)**
  - [ ] H1 (Highest): Runtime gate still prioritizes `scene.isAutoForward` over route/index inferred from double-chevron hotspot metadata.
  - [ ] H2: Export route precompute currently derives from scene-level flag instead of hotspot-level double-chevron state.
  - [ ] H3: First-hotspot/default fallback causes missed auto-forward when qualifying hotspot is not index 0.

- [ ] **Activity Log**
  - [ ] Update export route precompute to prioritize hotspot-level `targetIsAutoForward` and valid target.
  - [ ] Update runtime selector to use precomputed route first regardless of scene-level flag.
  - [ ] Keep manual scenes non-auto unless route or scene-level fallback exists.
  - [ ] Add regression tests and verify build.

- [ ] **Code Change Ledger**
  - [ ] Pending

- [ ] **Rollback Check**
  - [ ] Pending

- [ ] **Context Handoff**
  - [ ] If resumed: focus on `generateTourHTML` route derivation and `resolveScenePlaybackHotspot`. Route-first logic must trigger post-animation navigation for scenes containing a double-chevron hotspot, independent of incoming scene.
