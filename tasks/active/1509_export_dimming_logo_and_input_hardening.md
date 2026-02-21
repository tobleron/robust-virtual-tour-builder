# 1509 - Export Dimming, Logo Normalization, and Input Hardening

## Objective
Implement three export hardening improvements end-to-end:
1. Reduce over-aggressive UI dimming during export/system lock while preserving disabled behavior.
2. Guarantee logo assets are normalized to WebP quality 92 with bounded dimensions for both viewer usage and exported tours.
3. Enforce backend export input policy so scene images must satisfy frontend WebP-92 pipeline requirements, rejecting non-compliant uploads.

## Scope
- Frontend lock-state visual tuning (UtilityBar/FloorNavigation/SceneList/VisualPipeline/Viewer logo lock state).
- Frontend logo normalization pipeline for uploaded and exported logos.
- Frontend export scene normalization + policy marker.
- Backend multipart parser support for export policy field.
- Backend scene validation and rejection on non-compliance.
- Verification via ReScript build and Rust check.

## Acceptance Criteria
- [ ] Export/system-lock dimming remains clearly visible and disabled, but no longer appears overly transparent.
- [ ] Custom logo upload is converted to WebP q92 and size-bounded before storing in app state.
- [ ] Exported package logo is always emitted as optimized `logo.webp` at q92.
- [ ] Backend rejects export requests missing required scene policy or containing non-compliant scene assets.
- [ ] ReScript build passes and backend `cargo check` passes.
