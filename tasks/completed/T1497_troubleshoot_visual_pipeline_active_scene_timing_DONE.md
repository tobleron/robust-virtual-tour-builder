# 🛠️ TROUBLESHOOT: Visual Pipeline Active Scene Highlight Timing (T1497)

## 📌 Context
After confirming thumbnail progression is fixed, there is a suspected UX timing issue: visual pipeline squares appear to highlight the selected scene only after waypoint arrow animation starts, rather than immediately on scene selection/navigation start.

## ⚖️ Hypothesis (Ordered by Probability)
1. [x] **Derived State Delay**: Pipeline highlight uses a simulation/waypoint state that updates after transition start, not the immediate `activeIndex` transition intent.
2. [x] **Effect Timing**: Highlight effect runs on a dependency tied to navigation completion/animation kickoff instead of dispatch-time state.
3. [x] **Split Source of Truth**: Different modules (`VisualPipeline`, navigation overlays, waypoint animation) compute "active" from different scene IDs.
4. [ ] **Render Priority/Batching**: Highlight update is queued behind heavier scene transition work and appears delayed.

## 📝 Activity Log
- [x] Inspect highlight logic and selectors in `VisualPipeline.res` and related modules.
- [x] Trace scene selection event path from dispatch to highlight render.
- [x] Verify whether lag is code-level deterministic behavior.
- [x] Apply fix in `VisualPipeline.res` (effective active step fallback to current scene).
- [x] Run `npm run res:build`.
- [x] Run `npm run build`.

## 📑 Code Change Ledger
| File | Change | Revert Note |
|---|---|---|
| `src/components/VisualPipeline.res` | Added `effectiveActiveStepId` memo: use `activeTimelineStepId` only when it belongs to current `activeIndex` scene, otherwise fallback to current scene step for immediate highlight update. | Revert to direct `activeTimelineStepId` precedence logic in node render block. |
| `tasks/active/T1497_troubleshoot_visual_pipeline_active_scene_timing.md` | Updated troubleshooting record with root cause, fix, and verification status. | N/A |

## 🏁 Rollback Check
- [x] Confirmed CLEAN (working fix retained; no non-working edits remain).

## 🔄 Context Handoff
Lag root cause was validated and patched. `VisualPipeline` now computes an `effectiveActiveStepId` that validates explicit timeline-step selection against the current active scene and falls back to current-scene step when stale. Build gates pass, and task remains in `active` pending user runtime confirmation and explicit commit request.
