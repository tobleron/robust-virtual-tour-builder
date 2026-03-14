# 1865 Portal Access-Link Rewrite And Export Simplification

## Objective

Refactor the customer portal to use expiring private access links, a reusable uploaded tour library with multi-recipient assignment, global renewal settings, and `4k`-first delivery with `2k` fallback on small phones, while simplifying the publish dialog to expose only the production web package and standalone testing HTML.

## Scope

- Simplify publish options to:
  - `Web Package` (`4K` by default, `2K` on small phones)
  - `Standalone HTML` (`2K`, testing only)
- Replace customer username/password portal access with expiring access links.
- Separate tour uploads from recipient creation so one uploaded tour can be assigned to many recipients/brokers without re-uploading.
- Expose stable tour identifiers and recipient-specific direct links from the admin dashboard.
- Add global portal renewal/contact settings instead of per-customer renewal messages.
- Require uploaded portal tour packages to include both `tour_4k` and `tour_2k`.
- Migrate the portal/admin frontend from plain JS to ReScript.
- Keep the Rust backend as the only security boundary and preserve the portal-only deployment target.

## Constraints

- Do not regress the existing builder/export flows outside the publish dialog wording/choices.
- Preserve the already-fixed portal ZIP upload normalization and route bug fixes.
- Do not remove old portal DB structures in this pass if they can be safely left unused.
- Keep standalone HTML fixed to the existing testing-oriented `2K` behavior.

## Verification

- `npm run build`
- `npm run build:portal`
- `cd backend && cargo check`
- Focused local portal route checks with `curl`

## Notes

- Customer-facing portal access should be frictionless: private expiring link, session bootstrap, then clean URL.
- Portal delivery should prefer `4k`, with `2k` only on small phone-class viewports.
