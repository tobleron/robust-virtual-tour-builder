# T1540 Progress Spinner Regression

## Assignee
- Codex

## Objective
- Fix the regression where the export/teaser progress spinner no longer lives in the progress bar and instead floats near the right edge of the sidebar.

## Boundary
- Sidebar progress UI (`SidebarProcessing`, `UseSidebarProcessing`), global progress overlay CSS (`css/components/ui.css`), and any helpers that render or style the spinner that now appear outside the intended card.

## Owned Interfaces
- `SidebarProcessing.res`, `css/components/ui.css`, and any shared spinner visuals consumed by `ProgressBar`.

## No-Touch Zones
- Viewer renderers, backend services, `ProgressBar.res`.

## Hypothesis (Ordered Expected Solutions)
- [x] Reintroduce the spinner as part of the sidebar progress card so the animation stays anchored to the progress bar area instead of floating outside.
- [x] Hide the legacy `#processing-ui` spinner so it cannot duplicate the animation or appear in empty sidebar space.

## Activity Log
- [x] Confirmed the spinner is still showing inside the floating `#processing-ui` overlay while the sidebar card now has no spinner.
- [x] Added spinner markup back into the sidebar card and made the overlay’s spinner invisible.
- [x] Verified `npm run build` still succeeds after the layout/CSS tweaks.

## Code Change Ledger
- [x] `src/components/Sidebar/SidebarProcessing.res` – Render the spinner near the phase label so it stays inside the progress card.
- [x] `css/components/ui.css` – Hide the spinner inside `#processing-ui` and ensure the sidebar spinner inherits the proper shadow/animation.

## Rollback Check
- [x] Ensure the floating spinner disappears and the sidebar card animation remains visible before leaving the change.

## Context Handoff
- (No handoff content needed because the build will be green and logic documented.)
