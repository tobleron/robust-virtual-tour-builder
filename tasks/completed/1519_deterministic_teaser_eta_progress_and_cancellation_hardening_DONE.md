# Task 1519: Deterministic Teaser ETA, Progress, and Cancellation Hardening

## Assignee
Jules (AI Agent)

## Capacity Class
A

## Objective
Add robust user-facing progress and hardware-based ETA estimation for deterministic WebM generation, with reliable cancellation and state cleanup.

## Depends On
1518

## Boundary (Allowed Areas)
- `src/systems/TeaserLogic.res`
- `src/systems/OperationLifecycle.res`
- `src/components/Sidebar/SidebarActions.res`
- `src/components/Sidebar/SidebarProcessing.res`
- `src/utils/ProgressBar.res`
- `src/utils/Constants.res` (teaser progress/ETA constants only)

## Owned Interfaces
- Teaser progress lifecycle messaging and percent mapping
- ETA computation and update model
- Cancel/abort interaction and teardown behavior

## No-Touch Zones
- Teaser motion math internals and renderer core
- Navigation FSM and scene loader internals
- Backend API behavior

## Scope
1. Add preflight benchmark before deterministic render starts:
   - quick sample frame render throughput,
   - optional micro encode sample,
   - initial ETA estimation.
2. Introduce staged progress contract:
   - `Preparing`
   - `Benchmarking`
   - `Rendering Frames`
   - `Encoding WebM`
   - `Finalizing`
3. Continuously recalculate ETA using rolling throughput.
4. Harden cancel behavior:
   - cancel button + ESC cancel,
   - immediate stop of render/encode pipeline,
   - cleanup temporary buffers/resources,
   - reset app lock/progress states safely.
5. Emit telemetry for estimated vs actual runtime drift.

## Out of Scope
1. Changes to deterministic motion generation rules.
2. Backend MP4 implementation.
3. Export pipeline changes.

## Acceptance Criteria
- [ ] User sees a clear ETA before rendering begins.
- [ ] ETA updates during rendering/encoding and converges as work progresses.
- [ ] Cancel works during all teaser phases and leaves no stuck progress/lock state.
- [ ] On success/failure/cancel, operation lifecycle state is consistent and recoverable.
- [ ] `npm run res:build` passes.
- [ ] Affected frontend tests pass or are updated accordingly.

## Verification Evidence Required
1. ETA accuracy sample for `x445.zip` (initial estimate vs final actual duration).
2. Cancel test evidence from each phase.
3. Progress-state log showing full lifecycle transitions.
