# 1862 Deferred Portal Integration And Unit Test Alignment

## Objective

Add focused automated coverage for the new customer portal subsystem after the implementation and UX stabilize, instead of rewriting tests on every portal/admin iteration.

## Why Deferred

- The customer/admin portal is newly introduced and likely to receive UI and route refinements before rollout.
- Source verification was prioritized first with:
  - `cargo check`
  - `npm run build:portal`
  - `npm run build`
  - `npm run test:frontend`
- The existing frontend suite stayed green, but the new portal paths do not yet have dedicated contract/UI coverage.

## Target Modules / Files

- [backend/src/services/portal.rs](backend/src/services/portal.rs)
- [backend/src/api/portal.rs](backend/src/api/portal.rs)
- [backend/src/api/config_routes.rs](backend/src/api/config_routes.rs)
- [backend/src/main.rs](backend/src/main.rs)
- [backend/migrations/20260313000001_portal_access_links_and_library.sql](backend/migrations/20260313000001_portal_access_links_and_library.sql)
- [backend/migrations/20260313000002_portal_access_link_value.sql](backend/migrations/20260313000002_portal_access_link_value.sql)
- [backend/migrations/20260313000003_portal_access_link_short_code.sql](backend/migrations/20260313000003_portal_access_link_short_code.sql)
- [src/site/PortalApp.res](src/site/PortalApp.res)
- [src/site/PortalApi.res](src/site/PortalApi.res)
- [src/site/PortalTypes.res](src/site/PortalTypes.res)
- [src/portal-index.js](src/portal-index.js)
- [rsbuild.portal.config.mjs](rsbuild.portal.config.mjs)
- [Dockerfile.portal](Dockerfile.portal)

## Deferred Coverage Goals

- Backend:
  - portal recipient creation/update validation
  - portal access-link expiry/revocation behavior
  - access-link bootstrap redirects, short-code backfill, and direct-tour redirect safety
  - shared tour library assignment/unassignment behavior across multiple recipients
  - ZIP validation rejects malformed uploads
  - private asset route blocks expired or cross-customer access
  - portal admin allowlist/role gating
- Frontend:
  - route parsing for `/portal-admin`, `/portal/{slug}`, `/portal/{slug}/tour/{tourSlug}`
  - expired/unavailable gate rendering without customer username/password
  - admin create/update/upload/assignment flows
  - recipient gallery/direct-link rendering from stored access links and short access routes
  - iframe player wrapper rendering for valid tour sessions
- Deployment/build:
  - portal-only build emits `dist-portal`
  - `APP_SURFACE=portal` serves portal dist and hides builder APIs

## Exit Criteria

- Portal subsystem behavior is considered stable enough that test expectations are unlikely to churn on the next UI calibration pass.
