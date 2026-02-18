# T1462 - Troubleshoot: Non-auto-forward scene unexpectedly advances to last scene in exported tour

## Objective
- Reproduce and fix exported-tour behavior where a scene that is **not** marked auto-forward still advances automatically after animation.
- Preserve intended rule: only scenes with auto-forward (double-chevron) behavior should auto-advance in exported tours.
- Avoid regressions to simulation mode and normal hotspot navigation.

## Scenario Reported
- Project has 5 scenes.
- Two middle scenes are auto-forward.
- Last scene is not auto-forward.
- Scene before last is not auto-forward, but it still advances to last scene automatically.

## Scope
- Exported tour runtime behavior only (customer-facing export).
- Verify save/load + export data mapping do not leak stale auto-forward state.
- Validate runtime route resolution and fallback conditions.

## Hypothesis (Ordered Expected Solutions)
- [x] `resolveScenePlaybackHotspot` fallback logic still activates for non-flagged scenes due to permissive scene-level conditions; tighten guard so only explicit route fields trigger exported auto-forward.
- [x] Export precompute writes `autoForwardHotspotIndex` / `autoForwardTargetSceneId` for a non-auto-forward scene because of a false-positive `targetIsAutoForward` calculation; fix route candidate filtering.
- [x] Project load normalization rehydrates stale hotspot/scene auto-forward flags (e.g., from prior edits), causing export payload to include unintended route metadata; sanitize load-time flags before export.
- [x] Runtime retry / delayed DOM fallback selects first hotspot when route metadata is absent; remove fallback path that can infer auto-forward without explicit scene route.

## Activity Log
- [x] Created troubleshooting task file in `tasks/active`.
- [x] Reproduce with current build and inspect exported `sceneData` for affected scene.
- [x] Audit `src/systems/TourTemplates.res` route computation and runtime fallback.
- [x] Audit project load normalization in project loader/validator path.
- [x] Implement minimal fix with explicit gating.
- [x] Validate by running targeted unit tests and production build.

## Code Change Ledger
- [x] `src/systems/TourTemplates.res`: Removed scene-level auto-forward fallback in export runtime (`resolveScenePlaybackHotspot`) so non-flagged scenes cannot auto-advance; kept explicit route-only auto-forward.
- [x] `src/systems/TourTemplates.res`: Changed export precompute to derive `targetIsAutoForward` from hotspot metadata (`h.isAutoForward`) instead of target scene flag, and removed scene-level fallback route derivation.
- [x] `tests/unit/TourTemplates_v.test.res`: Updated auto-forward tests to enforce explicit hotspot-driven routes and added regression test preventing scene-level-only inference.
- [x] Revert note: No rollback required; all applied changes are retained after passing targeted tests and full build.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Export runtime now auto-advances only when the current scene has an explicit auto-forward route encoded from a hotspot marked auto-forward. Scene-level fallback paths were removed from `TourTemplates`, which prevents non-flagged scenes from advancing due to stale scene flags. Validation passed with `tests/unit/TourTemplates_v.test.bs.js` and full `npm run build`.
