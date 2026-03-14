# T1866 Troubleshoot Portal Admin Flash And Disappear

## Hypothesis (Ordered Expected Solutions)

- [ ] The portal admin ReScript app is throwing during initial render or first effect, so the shell appears briefly and then React unmounts into a blank/error state.
- [ ] The portal admin boot request is receiving an auth/session response shape that the frontend does not handle, causing a fatal decode or state transition after first paint.
- [ ] The portal entry HTML or portal JS bundle is loading correctly, but a route-level redirect or hydration mismatch is replacing the visible admin UI immediately after mount.

## Activity Log

- [x] Reproduce the flash/disappear behavior locally with the running portal backend
- [x] Inspect portal-admin network responses and runtime bundle behavior
- [x] Trace the first portal-admin bootstrap requests and decode path in the ReScript portal frontend
- [x] Apply the minimal fix and verify the portal-admin page remains mounted
- [x] Re-run local portal smoke checks after the fix
- [x] Reproduce the clipped/no-scroll portal-admin layout in a browser-sized viewport
- [x] Verify fresh `localhost` and `127.0.0.1` portal-admin loads behave the same
- [x] Add a dedicated portal-shell scroll container so the page no longer gets chopped by the global app `overflow: hidden`

## Code Change Ledger

- [x] `src/site/PortalApp.res`: replaced the broken scoped `Date` constructor path with `Date.fromTime(...)` for the default expiry draft so the admin surface no longer crashes on first render.
- [x] `src/site/PortalApp.res`: fixed the document-title binding to use a property setter on the document object instead of calling `document.title(...)` like a function during route title updates.
- [x] `css/components/portal-pages.css`: made `.portal-shell` a viewport-height scroll container with internal vertical overflow so portal admin content remains accessible even though the shared app shell globally hides page overflow.

## Rollback Check

- [x] Confirmed CLEAN or REVERTED non-working troubleshooting edits

## Context Handoff

The portal admin disappearance was caused by two frontend runtime crashes, not by routing or backend reachability. First render failed in `nowPlusDaysIsoLocal` because the custom binding compiled to `new Date.Date(...)`; after fixing that, the route-title effect still crashed because the code attempted to call `document.title(...)` instead of setting the property. After those were fixed, the remaining admin-page issue was layout clipping from the repo-wide `html/body { overflow: hidden; }`, so the portal shell was updated to scroll internally; fresh Playwright checks now show both `127.0.0.1` and `localhost` rendering the portal admin correctly.
