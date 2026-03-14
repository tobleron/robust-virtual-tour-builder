## Context

Portal admin actions currently force the dashboard back into a global loading state. The page jumps to the top after mutations like status changes, which makes the UI feel clumsy and hides the user’s working context. The generated gallery/direct tour links are also not obvious enough inside the admin surface.

## Hypothesis (Ordered Expected Solutions)

- [ ] `loadAdmin()` is always resetting the entire remote state to `Loading`, remounting the page and causing the scroll jump.
- [ ] Flash status messages are structurally fine; the real issue is the full-screen loading transition rather than the message component itself.
- [ ] Access links already exist in data but need stronger presentation and explicit copy/open actions in the recipient detail area.

## Activity Log

- [ ] Inspect portal admin refresh/update flow and flash rendering.
- [ ] Add a refresh path that preserves the mounted dashboard during mutations.
- [ ] Make gallery/direct access links more discoverable and easier to use.
- [ ] Verify portal build and full app build.

## Code Change Ledger

- [ ] `src/site/PortalApp.res` - preserve-ready refresh flow and clearer link actions. Revert if it breaks admin state transitions.
- [ ] `css/components/portal-pages.css` - compact status/link presentation polish. Revert if it harms portal readability.
- [ ] `src/bindings/DomBindings.res` or equivalent binding file - clipboard/open helpers if needed. Revert if browser bindings miscompile.

## Rollback Check

- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff

The admin dashboard currently remounts on every mutation because successful actions call the full loading path again. The next session should preserve the ready state during refreshes so scroll position remains stable and the flash message becomes unobtrusive. The user also wants the generated portal access links to be immediately obvious from the recipient details and tour assignment rows.
