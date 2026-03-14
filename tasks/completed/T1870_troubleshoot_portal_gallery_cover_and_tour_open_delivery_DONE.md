## Context

Portal customer tour cards are currently showing a raw equirectangular panorama instead of a proper centered thumbnail, and opening a tour leads to a browser "refused to connect" error. The player page currently embeds the published tour in an iframe even though the backend sets `X-Frame-Options: DENY` globally, which blocks that render path. The cover image path also appears to point directly at the first extracted panorama asset rather than a purpose-built thumbnail.

## Hypothesis (Ordered Expected Solutions)

- [ ] Customer tour opening fails because the portal player embeds `/portal-assets/.../index.html` in an iframe while the backend security headers explicitly deny framing.
- [ ] Gallery cover cards are using the first panorama asset from `assets/images/2k/` instead of a dedicated derived thumbnail.
- [ ] The clean fix is to create a dedicated portal launch/open path and generate/store a portal-specific cover thumbnail during ZIP extraction.

## Activity Log

- [ ] Inspect portal player rendering path and backend security header interaction.
- [ ] Inspect portal ZIP extraction and cover-path selection logic.
- [ ] Replace the broken iframe/open flow with a direct authenticated player launch path.
- [ ] Generate/store a proper portal cover thumbnail and wire gallery cards to it.
- [ ] Verify portal build, backend compile, and a local customer flow smoke check.

## Code Change Ledger

- [ ] `backend/src/services/portal.rs` - cover thumbnail generation and authenticated launch path support. Revert if it corrupts stored portal packages.
- [ ] `backend/src/api/portal.rs` - customer launch route if needed. Revert if routing conflicts with existing portal session flow.
- [ ] `backend/src/startup.rs` or headers path - only if a scoped framing exception is required; revert if it weakens global security.
- [ ] `src/site/PortalApp.res` - customer gallery/open-tour behavior and cover rendering wiring. Revert if customer route transitions regress.

## Rollback Check

- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff

The customer-facing portal currently fails at two different layers: covers are wrong because they point to a raw panorama, and the player fails because the tour is loaded in an iframe under `X-Frame-Options: DENY`. The likely correct fix is not to weaken global security headers, but to stop relying on iframe embedding for the portal player and instead use a direct launch route or redirect. The gallery should also own a dedicated stored thumbnail so the cover looks like the builder thumbnail rather than an equirectangular strip.
