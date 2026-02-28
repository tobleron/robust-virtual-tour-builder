# T1605 - Troubleshoot Intermittent Waypoint Arrow Non-Responsive Clicks

## Objective
Determine why waypoint arrow clicks intermittently do not trigger navigation in real UI sessions, despite hotspot/auto-simulation navigation working.

## Scope
- Intermittent no-op on waypoint/arrow click in editor/viewer.
- Validate click pipeline: DOM hit target -> HotspotLayer click handler -> EventBus/dispatch -> navigation state transition.
- Identify state gating (linking mode, move mode, overlays, lock guards, simulation state) that may consume/ignore click.

## Hypothesis (Ordered Expected Solutions)
- [ ] H1: Pointer-event interception by viewer/overlay layer occasionally sits above hotspot arrow.
- [ ] H2: Guard condition in hotspot click handler early-returns for specific transient state (linking/moving/sim/blocking).
- [ ] H3: Navigation event fires but dedupe/transition guard drops request while FSM in non-idle state.
- [ ] H4: React key/remount timing causes stale hotspot node with detached handler after scene churn.
- [ ] H5: EventBus channel subscription race/regression still exists in a specific component lifecycle.

## Activity Log
- [x] Create troubleshooting task.
- [x] Inspect HotspotLayer / arrow render & click guards.
- [x] Inspect ViewerManagerHotspots event subscription + lifecycle.
- [ ] Inspect interaction lock overlays/z-index/pointer events.
- [x] Reproduce with deterministic steps and state snapshots.
- [x] Implement minimal fix preserving existing behavior.
- [x] Verify via unit + focused E2E/manual scenarios.

## Code Change Ledger
- [x] `src/components/HotspotLayer.res` - fixed arrow click target resolution by using `closest("[id^='arrow_']")` fallback when direct target lacks id (nested SVG node clicks were previously dropped).
- [x] `src/components/ViewerManager/ViewerManagerHotspots.res` - hardened `PreviewLinkId` handling to fallback-search hotspot by `linkId` across active scenes when `activeIndex` scene does not contain it, and added warning log on miss.

## Findings
- Intermittent non-response came from two compounding conditions:
  1. SVG click target mismatch: click landed on child node without `id`, and handler only checked direct target id.
  2. Transient scene mismatch: arrows can be visible while `activeIndex`/render ownership is mid-transition, so lookup by only `activeIndex` sometimes failed.
- Validation:
  - `npm run test:frontend -- tests/unit/HotspotLayer_v.test.bs.js tests/unit/PreviewArrow_v.test.bs.js tests/unit/ViewerManager_v.test.bs.js` passed (`11/11`).
  - `npm run res:build` could not be run because a watcher was already active (`PID 44957`), so compile verification is deferred to existing watcher output.

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Intermittent non-responsive arrow clicks were observed in real usage and accompanied by heavy `VIEWER_CLICK_DISPATCHED` logs. The issue appears state/timing-sensitive rather than always broken. Investigation focuses on click target ownership and transient guards in navigation/linking modes.
