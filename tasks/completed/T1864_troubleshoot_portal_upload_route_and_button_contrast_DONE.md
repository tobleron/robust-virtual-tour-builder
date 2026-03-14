# T1864 Troubleshoot Portal Upload Route And Button Contrast

## Hypothesis (Ordered Expected Solutions)

- [ ] The portal admin upload route exists, but Actix path extraction is mismatched to the declared route parameter names, causing a false `404` on upload.
- [ ] The upload endpoint works for authenticated admin users, but the portal UI hides the real backend error behind a generic `HTTP_404`.
- [ ] Portal buttons are inheriting the shared site button palette intended for light surfaces, so portal-specific dark-surface overrides are required.

## Activity Log

- [x] Reproduce the upload flow with a real portal admin session and a real `web_only` ZIP
- [x] Inspect the backend route declarations and path extractor structs for portal admin endpoints
- [x] Apply the minimal backend fix and re-run the upload
- [x] Apply portal-specific button contrast overrides and verify the rendered styles
- [x] Normalize ZIP package-root detection so uploading a zipped `web_only` folder succeeds
- [x] Verify protected customer asset HTML loads through `/portal-assets/...` after customer sign-in

## Code Change Ledger

- [x] `backend/src/api/portal.rs`: removed camelCase serde renaming from path extractor structs so route parameters like `customer_id`, `tour_id`, and `tour_slug` bind correctly.
- [x] `css/components/portal-pages.css`: added portal-scoped button overrides so ghost/primary buttons remain readable on dark portal surfaces.
- [x] `backend/src/services/portal.rs`: normalized ZIP package-root detection so uploads work for direct `web_only/` packages, zipped `web_only` folders, and wrapped export folders containing `web_only/`.

## Rollback Check

- [x] Confirmed CLEAN or REVERTED non-working troubleshooting edits

## Context Handoff

The upload route reproduced with a real portal admin bearer token and a real `web_only` ZIP. The backend returned `404 missing field customerId`, which points to a serde path-name mismatch rather than a missing endpoint. Portal button contrast is a separate CSS issue: ghost buttons inherit dark text from the shared site framework and need portal-scoped overrides for dark backgrounds.
