# T1890 Troubleshoot Viewer Control CSS State And Waypoint Button

## Objective
Stabilize the builder viewer-control styling so disabled, busy, and active states are owned by a clear CSS architecture instead of scattered inline class strings and cross-file overrides, then fix the actual failing left-rail `#` label-menu control so it grays out during waypoint navigation like the rest of the viewer controls. Preserve the current look and feel, keep export control styling visually aligned where equivalent controls exist, and avoid broad app-wide CSS churn outside the viewer slice.

## Hypothesis (Ordered Expected Solutions)
- [x] The label-menu `#` button uses a weaker lock signal than the other left-rail controls during navigation, so it stays visually active while the utility buttons disable through capability checks.
- [x] The viewer-control CSS is split across too many ownership layers (`buttons.css`, `floor-nav.css`, `viewer-ui-controls.css`, `viewer-ui-overlays.css`, and inline Tailwind classes), causing state styling to fight itself.
- [x] Moving visual states into semantic CSS hooks and leaving only structural/layout classes in ReScript components makes disabled/busy styling deterministic.
- [x] Export CSS can keep its generated delivery model while still centralizing equivalent control tokens in `TourStyles.res`.

## Activity Log
- [x] Create the task and move it to `tasks/active/`.
- [x] Take the requested full snapshot checkpoint before refactoring.
- [x] Audit current viewer control ownership and identify which rules belong in builder control CSS versus overlay positioning.
- [x] Refactor builder viewer controls to semantic class/state hooks.
- [x] Refactor viewer CSS ownership to remove viewer-specific logic from generic button files and reduce cross-file override conflicts.
- [x] Fix the label-menu `#` control so it uses the same mutation-lock capability path as the rest of the left rail.
- [x] Align export viewer control tokens where equivalent controls exist.
- [x] Run build verification and perform targeted manual state checks.

## Code Change Ledger
- [x] `src/components/ViewerLabelMenu.res`: switched the label `#` control to semantic viewer-control classes and tied its disabled state to `CanMutateProject` in addition to existing busy signals.
- [x] `src/components/UtilityBar.res`: replaced inline visual state classes with semantic viewer rail/control classes for link and preview buttons.
- [x] `src/components/FloorNavigation.res`: moved floor controls onto the same semantic control contract and gated metadata mutation through `CanMutateProject`.
- [x] `src/components/PreviewArrow.res`: moved hotspot control color/state styling into semantic CSS classes while keeping the existing reveal/animation behavior intact.
- [x] `css/components/viewer-ui-controls.css`: introduced the viewer control system (`viewer-rail`, `viewer-control`, hotspot control modifiers) as the primary owner of builder viewer-control visuals.
- [x] `css/components/viewer-ui-overlays.css`: reduced this file to placement/responsive sizing responsibilities for viewer controls.
- [x] `css/components/buttons.css`: removed dead viewer-specific utility button rules from the generic button stylesheet.
- [x] `src/systems/TourTemplates/TourStyles.res`: centralized export control tokens for active, idle, and disabled touch/classic viewer controls.

## Rollback Check
- [x] Confirmed CLEAN for the current refactor slice. The pre-refactor baseline was checkpointed in `b8d1ecd27`, and the remaining working-tree changes are limited to the intended viewer-control CSS refactor files.

## Context Handoff
- [x] The actual failing left-rail `#` control was the label-menu trigger, which stayed active because it was not using the same mutation lock path as the other utility controls during navigation. The builder viewer controls now use a semantic CSS contract, and export equivalents now share centralized control tokens in `TourStyles.res`. Final user validation should focus on the left rail during waypoint navigation plus a quick regression pass on floor controls and export touch controls.
