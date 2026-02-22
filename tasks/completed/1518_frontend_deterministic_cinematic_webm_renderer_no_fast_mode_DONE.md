# Task 1518: Frontend Deterministic Cinematic WebM Renderer (No Fast Mode)

## Assignee
Jules (AI Agent)

## Capacity Class
B

## Objective
Replace realtime teaser recording with a deterministic offline WebM renderer that prioritizes smoothness and motion parity over speed, and remove fast/realtime mode from product behavior.

## Depends On
1517

## Boundary (Allowed Areas)
- `src/systems/Teaser*.res`
- `src/systems/TeaserPlayback.res`
- `src/systems/TeaserLogic.res`
- `src/systems/TeaserRecorder.res` (replacement/refactor target)
- `src/systems/ServerTeaser.res` (only if needed for payload contract continuity)
- `src/components/Sidebar/SidebarActions.res`
- `src/utils/Constants.res` (teaser-specific constants only)

## Owned Interfaces
- Frontend teaser rendering engine selection (deterministic only)
- Teaser encoding pipeline (WebM deterministic path)
- Teaser UI entry behavior (format options and mode policy)

## No-Touch Zones
- `src/core/Reducer.res`
- `src/core/State.res` (except minimal non-breaking teaser state extension if unavoidable)
- Navigation FSM core files (`src/systems/Navigation/NavigationFSM.res`, `src/systems/Navigation/NavigationSupervisor.res`)
- Backend teaser rendering internals

## Hard Requirements
1. No fast mode in UI or runtime path.
2. Teaser generation must run in deterministic offline mode (frame-index-driven timeline).
3. User must not see live viewer manipulation while teaser renders; progress UI remains visible.
4. Output motion must match simulation semantics except intro-pan capture:
   - First frame starts centered at waypoint-start.
   - Scene transitions use configured crossfade semantics.
   - Builder overlays are excluded; logo stays visible.

## Scope
1. Implement deterministic frame scheduler:
   - render by fixed timestamps (`t = frameIndex / fps`), not wall-clock.
2. Implement deterministic frame renderer from `motion-spec-v1`.
3. Implement deterministic WebM encode path (CFR output).
4. Remove realtime capture from user-facing teaser flow.
5. Keep MP4 as future-disabled option only (no active generation path in this task).

## Out of Scope
1. Backend MP4 renderer implementation.
2. Full teaser UX copy redesign.
3. New simulation algorithm changes outside teaser capture semantics.

## Sequential Plan
1. Introduce deterministic render loop and frame-state interpolation.
2. Integrate deterministic renderer with teaser operation lifecycle.
3. Encode rendered frame sequence to WebM with constant frame rate.
4. Remove fast/realtime mode toggles and dead runtime branches.
5. Verify visual parity with simulation behavior.

## Acceptance Criteria
- [ ] Teaser output is generated only through deterministic rendering path.
- [ ] No stutter caused by dropped realtime frames (frame count equals planned timeline frame count).
- [ ] Output begins at waypoint-start center (no intro-pan capture).
- [ ] Crossfade behavior appears between scenes as specified.
- [ ] Builder overlays are absent in output; logo remains visible.
- [ ] `npm run res:build` passes.
- [ ] `npm run test:frontend` passes for affected teaser tests.

## Verification Evidence Required
1. Frame accounting log: planned vs rendered vs encoded frame count.
2. Side-by-side note comparing simulation timeline duration vs output duration.
3. Short demo artifact from `x445.zip`.
