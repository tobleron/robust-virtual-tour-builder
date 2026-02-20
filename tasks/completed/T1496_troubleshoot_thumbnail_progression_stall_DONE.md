# 🛠️ TROUBLESHOOT: Thumbnail Progression Stalls After First Scene (T1496)

## 📌 Context
After the recent intro-pan/simulation timing fixes, thumbnail enhancement now generates only the first thumbnail (first scene) and stops processing subsequent scenes. This troubleshooting focuses on restoring deterministic sequential thumbnail generation while preserving the simulation pause behavior introduced in T1494. Keep T1495 audit goals in mind (event serialization / stale-state protection) while applying a minimal safe fix.

## ⚖️ Hypothesis (Ordered by Probability)
1. [ ] **Ref/Render Deadlock**: `isProcessing.current` is reset inside `setTimeout`, but no state change occurs after that reset, so the effect never re-runs once it observed `isProcessing.current == true`.
2. [ ] **Effect Dependency Gap**: Dependencies (`state.inventory`, `processedIds`, `state.simulation.status`) may not change on expected paths after the first patch, preventing the next enhancement cycle.
3. [ ] **Selection Filter Drift**: `processedIds` / `tinyFile` predicate may classify all remaining scenes as ineligible due to stale state shape from inventory projections.
4. [ ] **Image Load Lifecycle Leak**: Event listeners or per-image cleanup ordering may leave the system in a pseudo-busy state after first success.

## 📝 Activity Log
- [x] Reproduce/trace thumbnail pipeline behavior in `ThumbnailProjectSystem.res`.
- [x] Confirm state/effect loop around `isProcessing`, `processedIds`, and dependencies.
- [x] Apply minimal deterministic fix to resume sequential processing.
- [x] Run `npm run res:build`.
- [x] Run `npm run build`.
- [ ] Validate runtime behavior in app and archive task (deferred until user requests commit proof).

## 📑 Code Change Ledger
| File | Change | Revert Note |
|---|---|---|
| `src/systems/ThumbnailProjectSystem.res` | In `cleanup`, clear `isProcessing.current` synchronously before `setProcessedIds` to ensure the next render sees unlocked processing and advances to next scene. | Revert `cleanup` ordering to previous timed reset if needed. |

## 🏁 Rollback Check
- [x] Confirmed CLEAN (working change retained; no non-working edits left in this troubleshooting pass).

## 🔄 Context Handoff
Root cause was the `isProcessing` reset happening in a delayed callback after the final render-triggering state updates, which left the loop locked with no new render to re-enter processing. The fix now clears `isProcessing.current` synchronously before `setProcessedIds`, so each completion schedules the next enhancement pass deterministically. Next session should verify this behavior in-browser across multi-scene projects and keep task active until user requests commit proof.
