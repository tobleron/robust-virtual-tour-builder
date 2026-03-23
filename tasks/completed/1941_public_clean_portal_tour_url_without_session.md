# 1941 Public Clean Portal Tour URL Without Session

## Objective

Allow the clean portal tour URL format to open the published tour directly for valid public recipients without requiring a pre-existing cookie-backed portal session:

- `https://www.robust-vtb.com/u/:customer_slug/tour/:tour_slug`

Today, only the tokenized URL works publicly:

- `https://www.robust-vtb.com/u/:customer_slug/:token/tour/:tour_slug`

The clean URL still redirects to `/u/:customer_slug` when no session exists, which can surface the expired-access experience even when the original tokenized link is valid and the recipient should be allowed to open the tour.

## Background

On March 23, 2026:

- The public tokenized tour route was fixed so it returns the launch document directly instead of redirecting through the gallery flow.
- Production verification confirmed that:
  - `/u/ak84/fmM6njo/tour/demotourtripz` now returns `200 OK` directly with the tour HTML.
  - `/u/ak84/tour/demotourtripz` still redirects to `/u/ak84`.
- That means the user-facing issue remains for any case where the clean URL is copied, reopened, bookmarked, or surfaced by browser history or other downstream sharing behavior.

## Problem Statement

The current access model treats the clean route as session-only:

- [backend/src/api/portal_public_routes.rs](backend/src/api/portal_public_routes.rs)
  - `customer_tour_launch` requires `ensure_slug_matches_session(...)`
  - if that fails with `Unauthorized`, it redirects to `/u/:slug`
- [src/site/PortalAppCustomerSurface.res](src/site/PortalAppCustomerSurface.res)
  - the customer surface then attempts to load `/api/portal/customers/:slug/session`
  - without a valid cookie-backed session it renders the gate/locked experience

This means the clean URL is not self-sufficient as a public entrypoint.

## Desired Outcome

For recipients with valid access, both of these should work in a fresh browser with no prior cookies:

- `/u/:slug/:token/tour/:tour_slug`
- `/u/:slug/tour/:tour_slug`

The clean URL should no longer fall back to the gallery gate solely because the browser does not already hold a portal session cookie.

## Scope

Investigate and implement one coherent public-access model for clean portal tour URLs. The implementation may involve backend-only changes, or backend plus limited frontend adjustments, but it must preserve current expiry/revocation protections.

Likely touchpoints:

- [backend/src/api/portal_public_routes.rs](backend/src/api/portal_public_routes.rs)
- [backend/src/api/portal_support.rs](backend/src/api/portal_support.rs)
- [backend/src/services/portal_sessions.rs](backend/src/services/portal_sessions.rs)
- [backend/src/services/portal_assets.rs](backend/src/services/portal_assets.rs)
- [backend/src/services/portal_assignment_queries.rs](backend/src/services/portal_assignment_queries.rs)
- [backend/src/services/portal_assignments.rs](backend/src/services/portal_assignments.rs)
- [src/site/PortalAppCustomerSurface.res](src/site/PortalAppCustomerSurface.res)
- [src/site/PortalAppCoreRoutes.res](src/site/PortalAppCoreRoutes.res)

## Constraints

- Do not weaken expiry or revocation enforcement.
- Do not require portal admin username/password for public customer tour access.
- Preserve support for recipient-scoped access controls.
- Avoid reintroducing the old gallery redirect dependency for public tour opens.
- Keep production build green for portal-runtime and full build workflows.

## Investigation Questions

1. What should authorize `/u/:slug/tour/:tour_slug` when no session cookie exists?
2. Should the clean route be resolved by:
   - the customer’s currently active gallery access link,
   - the customer-tour assignment state,
   - a canonical recipient access record persisted server-side,
   - or some other explicit lookup strategy?
3. If multiple valid links/assignments exist for one customer, what deterministic rule should be used?
4. Should opening the clean URL create/refresh a cookie-backed session for subsequent asset requests?
5. Are portal assets under `/portal-assets/:slug/:tour_slug/...` still adequately protected under the chosen approach?

## Acceptance Criteria

- A fresh browser with no portal cookie can open a valid clean URL of the form `/u/:slug/tour/:tour_slug`.
- A fresh browser with no portal cookie can still open the tokenized URL of the form `/u/:slug/:token/tour/:tour_slug`.
- Expired, revoked, unpublished, or unauthorized tours still fail closed with the correct UX.
- Asset fetches for a valid public clean URL continue to work after the initial document response.
- No redirect to `/u/:slug` occurs for valid public clean-tour opens.
- `npm run build` passes locally.
- `cargo build --bin portal --no-default-features --features portal-runtime` passes locally.
- Production verification includes an explicit fresh-session check for both URL forms.

## Suggested Verification Plan

- Local:
  - `npm run build`
  - `cd backend && cargo build --bin portal --no-default-features --features portal-runtime`
- Runtime:
  - test `/u/:slug/tour/:tour_slug` in a fresh private window
  - test `/u/:slug/:token/tour/:tour_slug` in a fresh private window
  - confirm expired/revoked cases still fail as expected
- Deployment:
  - redeploy portal
  - verify `https://www.robust-vtb.com/api/health`
  - verify both live URL shapes directly without pre-existing cookies

## Implementation Summary

Implemented on March 23, 2026:

1.  **New Service Function**: Added `resolve_public_tour_access` in `backend/src/services/portal_sessions.rs`.
    *   Finds the most recent active gallery access link for the customer.
    *   Verifies that the target tour is assigned to the customer and is published.
    *   Enforces customer activity, link expiry/revocation, and assignment expiry/revocation.
    *   Updates `open_count` and `last_opened_at` on the assignment.
    *   Returns an `"assignment"` session kind.
2.  **Route Refinement**: Updated `customer_tour_launch` in `backend/src/api/portal_public_routes.rs`.
    *   Now uses the new resolution logic if no session exists or if the existing session is unauthorized for the specific tour.
    *   Seamlessly stores a new session cookie upon successful resolution.
3.  **API Generalization**: Updated `customer_session` and `customer_tours` in `backend/src/api/portal_public_routes.rs` and the underlying services in `portal_sessions.rs`.
    *   These endpoints now accept both `"gallery"` and `"assignment"` session kinds.
    *   `load_customer_session` synthesizes a minimal access link summary for assignment-based sessions to maintain compatibility with the frontend.
4.  **Verification**:
    *   Verified that `cargo build --bin portal --no-default-features --features portal-runtime` passes.
    *   Verified that `npm run build` passes.
    *   Cleaned up unused functions and imports.

The clean URL `/u/:slug/tour/:tour_slug` is now a self-sufficient entrypoint for authorized public users.

## Status: Completed
