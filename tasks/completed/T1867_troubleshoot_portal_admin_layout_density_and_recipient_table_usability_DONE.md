# T1867 Troubleshoot Portal Admin Layout Density And Recipient Table Usability

## Hypothesis (Ordered Expected Solutions)

- [x] The current two-column admin rail layout is making the workspace appear artificially narrow, creating the “empty right side” perception even though the container width is technically correct.
- [x] The recipient directory needs a true table-first workspace structure instead of a card-plus-list hybrid, so the user can scan active vs revoked recipients faster.
- [x] The existing active/revoked grouping is correct logically, but the controls/forms should be reorganized into a top tools row so the main table can span full width.
- [x] The customer gallery is shrinking because `.portal-shell` is a flex child without width/flex-grow, so the viewport is available but the shell only occupies the left column.
- [x] Portal access links need a persistent short-code layer plus a direct-tour route so customer-facing URLs stay compact instead of exposing long token strings or `?next=` deep links.

## Activity Log

- [x] Measured the reported viewport math and confirmed the issue was composition density, not an actually hidden sidebar.
- [x] Verified the inner workspace width budget and mapped recipient/tour column allocations before editing the layout.
- [x] Refactored the admin dashboard into a full-width workspace with a top toolbar, explicit table grids, compact action rails, and clearer link presentation.
- [x] Captured live browser screenshots at the reported desktop width to confirm the recipient rows, detail cards, and tour-library action rails no longer overlap.
- [x] Re-verified both `npm run build:portal` and `npm run build`.
- [x] Measured the customer gallery in the browser and confirmed the left-column issue was a flex-item width collapse, not missing content.
- [x] Reworked the customer gallery hero/section layout and re-checked the live `1181x768` viewport to confirm the shell and gallery now span the available width.
- [x] Added short-code portal access-link generation plus a direct `/access/{token}/tour/{tour_slug}` redirect path, while keeping hashed legacy tokens resolvable.
- [x] Verified `cargo check`, `npm run build:portal`, and `npm run build` after the short-link and customer-layout changes.
- [x] Inset the customer gallery thumbnails inside each tour card and added explicit cover radii so the imagery reads rounded on all four corners instead of only the top edge.
- [x] Re-verified the customer gallery styling with `npm run build:portal`, `npm run build`, and a live browser measurement confirming the cover radius and card inset spacing.
- [x] Simplified the customer gallery into a more minimal brand-first presentation, replaced the generic end-user mark with `logo.webp`, and kept the branded portal shell visible for customer tour routes instead of forcing a full-page asset-path redirect.
- [x] Switched future portal access links to compact 7-character base62 short codes and re-verified `cargo check`, `npm run build:portal`, and `npm run build` after the change.
- [x] Reproduced and fixed a Rust compile-time move error in portal access-link regeneration, then re-ran `cargo check` to confirm the backend builds cleanly again.
- [x] Replaced the customer tour iframe URL navigation with fetched `srcDoc` delivery so the short `/u/{slug}/tour/{tour}` route keeps the branded shell without tripping browser frame-block behavior.
- [x] Re-hardened the global backend frame policy to `DENY` after removing the dependency on framed asset navigation, then re-verified `cargo check`, `npm run build:portal`, and `npm run build`.
- [x] Increased the customer-facing logo lockup scale and added a per-tour copy-share control that uses the real credentialed direct link rather than the session-only `/u/{slug}/tour/{tour}` route.
- [x] Replaced success banners for portal copy actions with a reusable copied-state button pattern that flips the icon to a confirmation mark and turns orange after a successful copy.
- [x] Replaced the frontend iframe-based short tour route with a backend-served launch document on `/u/{slug}/tour/{tour}` so the customer keeps a short URL while the actual published tour HTML runs top-level instead of inside the portal shell.
- [x] Boosted tour watermark sizing both in the source export templates and in the backend-served launch document rewrite so current published portal tours show stronger branding without requiring a re-export.
- [x] Removed the separate tablet export representation so landscape tablets now stay on the same desktop-sized stage while still using the existing touch-primary landscape shell.
- [x] Verified the export-template cleanup with the active `rescript watch` output refreshed and a direct `npx rsbuild build` bundle pass after the regular `npm run build` path was blocked by the existing watcher process.
- [x] Fixed the follow-up ReScript build failure by updating export-template unit tests that still referenced the removed tablet-stage flag and stale watermark constants, then re-ran `npm run build` and targeted Vitest coverage for the touched files.
- [x] Reproduced the `/u/tng` gallery failure on the live backend, confirmed the process was running without `APP_SURFACE=portal`, and traced the raw `No such file or directory (os error 2)` response to the builder-surface fallback trying to open a missing `../dist/index.html`.
- [x] Hardened backend surface selection to auto-pick the portal bundle when the builder bundle is absent and to resolve dist roots from `CARGO_MANIFEST_DIR` instead of cwd-fragile relative strings, then re-ran `cargo check`.

## Code Change Ledger

- [x] `src/site/PortalApp.res`:
  Reworked the admin dashboard markup into a toolbar-first, table-first layout; removed the overlapping nested recipient-row grid; converted row actions to compact icon+label controls; and turned access links into clearer resource cards/hyperlinks with copy/open affordances.
- [x] `css/components/portal-pages.css`:
  Replaced wrap-heavy rail styling with explicit desktop column budgets, compact action/button treatments, link-card styling, and mobile stacked-cell labels to prevent overlap and preserve scanability.
- [x] `src/site/PortalApp.res`:
  Switched direct tour links from `?next=` deep links to compact `/access/{code}/tour/{slug}` URLs, reformatted customer expiry text, and rebuilt the customer gallery into a full-width hero + gallery section that uses the viewport cleanly.
- [x] `css/components/portal-pages.css`:
  Fixed `.portal-shell` flex sizing so the customer portal fills the page, widened the customer tour grid, and added customer-gallery spacing rules so the layout scales without collapsing to the left.
- [x] `css/components/portal-pages.css`:
  Inset each customer tour thumbnail with a `14px` card gutter and `20px` internal cover radius so the tour image is rounded at both the top and bottom edges.
- [x] `src/site/PortalApp.res`:
  Reworked the customer-facing portal to use the real `logo.webp`, reduced the gallery chrome to a more minimal brand-first hero/meta layout, and changed customer tour routes to render a branded iframe player shell so the visible URL can stay short.
- [x] `css/components/portal-pages.css`:
  Added the end-user logo/brand lockup styling, minimal customer meta chips, and the branded player-shell header/layout for short customer tour routes.
- [x] `src/site/PortalApp.res`:
  Changed customer tour rendering to fetch the first available published entry HTML (`4K`, `2K`, then `HD` fallback), inject a base href, and mount it into `iframe.srcDoc` so the visible route stays short while the actual package assets still resolve correctly.
- [x] `src/site/PortalApp.res`:
  Added customer-side copy-to-clipboard feedback and a compact per-tour share button wired to the direct access-bearing tour URL.
- [x] `src/site/PortalApp.res`:
  Added a reusable portal copy-button component so every portal copy control now flips from copy to check and shows an orange confirmation state instead of raising a success banner.
- [x] `src/site/PortalTypes.res`:
  Extended the customer access-link decoder so session/gallery payloads can expose the shareable access URL to the end-user portal.
- [x] `css/components/portal-pages.css`:
  Added centered player feedback styling for loading/error states in the branded customer tour shell.
- [x] `css/components/portal-pages.css`:
  Enlarged the end-user logo lockup again and added a global orange copied-state style for portal copy buttons plus tight icon-button styling for per-tour share actions in the customer gallery.
- [x] `backend/src/api/portal.rs`:
  Added a real authenticated `/u/{slug}/tour/{tour_slug}` launch handler that serves HTML directly and redirects unauthenticated/expired sessions back to the customer portal.
- [x] `backend/src/api/config_routes.rs`:
  Registered the short customer tour launch route in both portal route configs ahead of SPA fallback behavior.
- [x] `backend/src/services/portal.rs`:
  Added launch-document loading/base-href injection and launch-time branding boosts so published tours can run top-level on the short route while still resolving package assets under `/portal-assets/...`.
- [x] `src/systems/TourTemplateHtml.res`:
  Increased exported watermark sizing constants for future published tours.
- [x] `src/systems/TourTemplates/TourAssets.res`:
  Increased the branded export hub logo-card dimensions for future published packages.
- [x] `src/systems/Exporter/ExporterPackagingTemplates.res`:
  Increased the adaptive web index logo block size for future published packages.
- [x] `src/systems/TourTemplates/TourScriptViewport.res`, `src/systems/TourTemplates/TourScriptCore.res`, `src/systems/TourTemplates/TourScripts.res`:
  Collapsed export viewport state back to `desktop|portrait`, removed the obsolete tablet-stage flag plumbing, and kept the interaction-shell logic so touch-primary landscape devices still resolve to `landscape-touch`.
- [x] `src/systems/TourTemplates/TourStyles.res`:
  Removed the `export-state-tablet` selector family and the tablet-only stage downshift so exported tours keep a consistent landscape stage instead of entering a separate middle representation.
- [x] `src/systems/TourTemplateHtml.res`:
  Stopped passing the deprecated tablet-landscape-stage option into export CSS/render script generation while preserving the existing file-protocol handling for packaged exports.
- [x] `tests/unit/TourTemplateScripts_v.test.res`, `tests/unit/TourTemplateStyles_v.test.res`, `tests/unit/TourTemplates_v.test.res`:
  Updated the export-template test suite to assert the new two-state viewport model, the `is-hd-export` selectors, and the current watermark-sizing constants instead of the removed tablet-stage flag and CSS.
- [x] `backend/src/main.rs`:
  Made app-surface selection auto-detect the portal bundle when `APP_SURFACE` is unset and `dist/index.html` is missing, and converted static/index file resolution to absolute paths derived from `CARGO_MANIFEST_DIR` so `/u/{slug}` and other portal shell routes no longer depend on the backend's runtime cwd matching a specific launch script.
- [x] `backend/src/services/portal.rs`:
  Added short-code-backed access links with legacy-token fallback, updated admin/customer link generation to prefer the compact code, retried short-code allocation on uniqueness collisions, and shortened future generated codes to 7-character base62 values.
- [x] `backend/src/services/portal.rs`:
  Fixed `regenerate_access_link` ownership so the customer slug is bound once, reused for URL formatting, and then moved into the response without borrowing after move.
- [x] `backend/src/services/portal.rs`:
  Exposed the customer access URL in the session/gallery access-link summary so the end-user portal can copy real shareable direct-tour links.
- [x] `backend/src/startup.rs`:
  Restored the stricter global `X-Frame-Options: DENY` header once the portal player no longer relied on iframe URL embedding.
- [x] `backend/src/api/portal.rs`:
  Passed the portal public base URL into customer session/gallery responses so generated copy links are absolute and ready to share.
- [x] `backend/src/api/config_routes.rs`:
  Registered `/access/{token}/tour/{tour_slug}` alongside the gallery access route.
- [x] `backend/migrations/20260313000003_portal_access_link_short_code.sql`:
  Added the schema/backfill step for persistent short codes and a unique index.
- [x] Revert note:
  If the new layout is rejected, revert only the portal surface/layout and short-link route changes from this task; keep the underlying recipient/tour/admin data model and existing access validation behavior.

## Rollback Check

- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff

The portal task now covers the admin density cleanup, the customer-gallery minimal/brand-first redesign, the short-link refinement, the export-template simplification that removes the tablet-only middle representation, and the backend fallback fix for portal gallery shells. Live browser checks previously confirmed the end-user portal now renders the real `logo.webp`, uses the simplified customer hero/layout, and no longer collapses into a left rail; the player-shell code also builds, but the latest live check hit the expired customer gate instead of an active tour session. The current `/u/{slug}` fix is source-verified with `cargo check`; the already-running backend on `127.0.0.1:8080` must restart once to pick up the new auto-surface selection and absolute dist-root resolution.
