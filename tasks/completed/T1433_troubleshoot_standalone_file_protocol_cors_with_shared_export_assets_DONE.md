# T1433 - Troubleshoot Standalone File-Protocol CORS with Shared Export Assets

## Objective
Fix standalone exported tours failing under `file://` due to browser CORS/WebGL restrictions after introducing shared root image assets.

## Target Outcome
- `web_only` keeps shared root `assets/images/<res>/...` architecture.
- `standalone` works when opened directly from extracted files (no local server required).
- Export package still supports clean client delivery without requiring `web_only` image subtree.

## Hypothesis (Ordered Expected Solutions)
- [x] Browsers block XHR/WebGL texture pipeline for `file://` image URLs used by panorama renderer.
- [x] Standalone must inline panorama assets (data URIs) to avoid cross-origin file restrictions.
- [x] Hybrid export strategy (shared assets for web_only + inline standalone HTML) will satisfy both use cases.

## Activity Log
- [x] Reproduce/confirm path in backend package writer causing standalone file protocol failures.
- [x] Reintroduce standalone data-URI embedding path while preserving shared root assets for web_only.
- [x] Verify backend compile and frontend build.

## Code Change Ledger
- [x] `backend/src/services/project/package.rs` - implement hybrid export writer: shared root assets for web_only, inline panorama assets for standalone.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Shared root assets are valid for hosted mode but standalone local-file opening triggers browser CORS and WebGL texture restrictions on `file://`-loaded panorama images. Standalone must avoid direct file URL loading for panoramas by embedding scene data as data URIs. The packaging pipeline should preserve shared root assets for web_only while generating standalone-specific embedded HTML.
