# 1861 Customer Tour Portal And Portal-Only Hyperlift Target

## Objective

Implement a branded customer tour portal inside the existing repository, backed by SQLite, with customer-specific login URLs, expiry-based access control, internal admin management, uploaded `web_only 2k` tour package publishing, and a portal-only deployment target suitable for Hyperlift.

## Scope

- Keep the portal in the same repo, but isolate it from the builder as a separate frontend/backend surface.
- Add customer-facing portal routes with:
  - unique customer slug URL
  - username/password login
  - expiry-aware access
  - branded gallery of assigned tours
- Add internal admin routes/UI for:
  - customer creation/edit
  - username/password setup
  - expiry date management
  - `web_only 2k` ZIP upload
  - publish/unpublish of tours
- Persist portal data in SQLite using the existing backend database setup.
- Store uploaded customer tour packages privately on disk and serve them only through authenticated backend routes.
- Add a portal-only backend binary and portal-only frontend build/deploy target suitable for Hyperlift.
- Keep future payment support out of scope for implementation, but preserve schema/runtime readiness via billing/expiry fields.

## Constraints

- Do not expose the builder frontend or builder APIs in the portal-only deployment target.
- Do not regress existing builder/dashboard/auth flows.
- Prefer the existing site shell where possible for consistent branding.
- Customer credentials are created manually by admin only; no self-signup or self-service password reset in v1.
- Customer-facing deployed tours use only the exported `web_only 2k` package.

## Verification

- `npm run build`
- `npm run test:frontend`
- `cd backend && cargo check`
- Narrow backend tests for portal auth/storage/upload logic as added

## Notes

- The portal deployment target should be buildable from this repo without shipping the builder UI.
- The initial hosting target is Hyperlift with SQLite on disk and private extracted tour storage on disk.

## Implementation Notes

- Added SQLite portal schema in [backend/migrations/20260312000000_portal_customer_access.sql](backend/migrations/20260312000000_portal_customer_access.sql) for:
  - `portal_customers`
  - `portal_users`
  - `portal_tours`
  - `portal_audit_log`
- Added Rust portal service logic in [backend/src/services/portal.rs](backend/src/services/portal.rs):
  - portal customer/user/tour models
  - Argon2 password hashing for portal users
  - expiry-aware access-state computation
  - private `web_only 2k` ZIP extraction
  - authenticated asset resolution from private disk storage
  - admin-email allowlist support via `PORTAL_ADMIN_EMAILS`
- Added portal API routes in [backend/src/api/portal.rs](backend/src/api/portal.rs) and registered them in [backend/src/api/config_routes.rs](backend/src/api/config_routes.rs):
  - customer sign-in/session/sign-out/gallery
  - admin customer create/update/list
  - admin tour upload/list/status update
  - protected `/portal-assets/...` file serving
- Added backend surface gating in [backend/src/main.rs](backend/src/main.rs):
  - `APP_SURFACE=portal` serves portal-only frontend dist
  - portal mode configures only auth + portal APIs, not builder/project/media APIs
- Added portal-only frontend entry/build target:
  - [src/portal-index.js](src/portal-index.js)
  - [src/site/PortalApp.js](src/site/PortalApp.js)
  - [rsbuild.portal.config.mjs](rsbuild.portal.config.mjs)
  - [Dockerfile.portal](Dockerfile.portal)
- Added portal-specific styling in [css/components/portal-pages.css](css/components/portal-pages.css), imported from [css/style.css](css/style.css).
- Portal UX currently includes:
  - `/portal/{customer_slug}` customer login and gallery
  - `/portal/{customer_slug}/tour/{tour_slug}` wrapper player with authenticated iframe
  - `/portal-admin/signin` admin sign-in
  - `/portal-admin` admin customer/tour management

## Verification Notes

- `cd backend && cargo check`
- `npm run build:portal`
- `npm run build`
- `npm run test:frontend`
- `cd backend && cargo test slugify_normalizes_and_strips_noise`
