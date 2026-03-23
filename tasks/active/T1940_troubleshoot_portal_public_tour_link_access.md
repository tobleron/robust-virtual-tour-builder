Assignee: Codex
Capacity Class: A
Objective: Determine why a generated portal tour link can show the expired-link page instead of the actual tour, and confirm whether the specific live URL is publicly accessible without portal username/password credentials.
Boundary: src/site/, backend/src/api/, backend/src/services/, tasks/active/T1940_troubleshoot_portal_public_tour_link_access.md
Owned Interfaces: Portal route parsing, portal public route handlers, portal access/session resolution, portal asset launch/serve flow
No-Touch Zones: src/core/, src/systems/Navigation/, backend/src/api/media/, backend/src/services/project/
Independent Verification: Source-trace the public portal URL resolution path, inspect any auth/expiry gating in code, and compare that logic with the live URL response observed at `http://www.robust-vtb.com/u/ak84/fmM6njo/tour/demotourtripz`.
Depends On: None
Merge Risk: Low; investigation-only unless a narrowly scoped fix is requested later.

# T1940 Troubleshoot Portal Public Tour Link Access

- [ ] Hypothesis (Ordered Expected Solutions)
  - [ ] The public `/u/:customer/:token/tour/:slug` route is incorrectly requiring or inferring an authenticated portal session instead of treating the tokenized URL as sufficient access.
  - [ ] The tokenized customer link or tour assignment behind this URL is expired/revoked in backend data, so the portal is correctly routing to the expired-link experience.
  - [ ] The frontend portal route parser or customer surface is dropping the token/tour context and falling back to an expired state despite a valid backend response.
  - [ ] The live site is serving mismatched frontend/backend versions, so the generated URL format and backend resolution logic no longer agree.

- [ ] Activity Log
  - [x] Read repo context docs and task workflow.
  - [x] Read portal/public route and portal access services.
  - [x] Inspect frontend portal route parsing and customer surface.
  - [x] Check the live URL response behavior and compare against source expectations.
  - [x] Summarize whether the URL should be publicly accessible and what is actually happening.
  - [x] Patch public token tour handlers to serve the launch document directly after token validation/session creation instead of redirecting through the clean customer tour/gallery URL.
  - [x] Verify with `npm run build`.

- [ ] Code Change Ledger
  - [x] [backend/src/api/portal_public_routes.rs](backend/src/api/portal_public_routes.rs): Changed `/u/{slug}/{token}/tour/{tour_slug}` and `/access/{token}/tour/{tour_slug}` to return the launch HTML directly after storing the session, preserving the tokenized URL and avoiding the gallery redirect; no revert needed.

- [ ] Rollback Check
  - [x] Confirmed CLEAN. Working change retained after successful build verification.

- [ ] Context Handoff
  - [x] Tokenized public links are intended to bypass portal username/password by creating a cookie-backed customer session via backend redirect handlers.
  - [x] On March 23, 2026, the live URL `/u/ak84/fmM6njo/tour/demotourtripz` returned `302` with a session cookie, then `/u/ak84/tour/demotourtripz` returned the actual tour HTML and the customer session API reported `canOpenTours: true`, `expired: false`, and expiry `2026-04-14T11:54:00+00:00`.
  - [x] The clean URL `/u/ak84/tour/demotourtripz` without that bootstrap session returned `302` to `/u/ak84`, so reports of failure are most likely caused by sharing/copying the post-redirect URL instead of the original tokenized URL, or by a separately expired/revoked token on other links.
  - [x] The fix keeps tokenized tour URLs on their original path by serving the launch document directly from the token route, so refresh/share/bookmark no longer depend on a clean-session URL that can fall back to the gallery state.
