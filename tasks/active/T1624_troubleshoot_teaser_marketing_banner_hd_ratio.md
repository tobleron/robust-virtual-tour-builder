# T1624 - Troubleshoot + Implement Teaser Marketing Banner HD-Proportional Overlay

## Objective
Add marketing bottom banner overlay to teaser rendering with sizing/spacing proportional to the HD export banner baseline, while preserving current teaser generation stability.

## Current Working State (Baseline Snapshot)
- Teaser generation currently produces output successfully (deterministic renderer path operational).
- HUD overlays currently include: room label, floor nav, and logo watermark.
- Teaser does **not** currently draw the marketing banner overlay (comment/phone/rent/sale) in the rendered frames.
- Prior strict scene-readiness abort patch was rolled back; renderer currently uses stable baseline plus canvas source fallback.

## Hypothesis (Ordered Expected Solutions)
- [x] Highest probability: add a dedicated marketing banner draw function in `TeaserRecorderHud.res` using HD reference constants, then scale with existing HUD scale model.
- [x] Wire marketing payload into teaser overlay model so `TeaserOfflineCfrRenderer` passes static banner state to each frame draw.
- [x] Keep portrait-specific export layout out of teaser path (teaser target is HD-ratio path only).
- [x] Validate by build + focused teaser unit tests to ensure no rendering-path regressions.
- [x] Refine segment corner rendering so only true outer top corners are rounded; middle chip segments remain flat as in export.

## Activity Log
- [x] Create troubleshooting task with baseline snapshot and rollback ledger.
- [x] Implement HD-proportional teaser marketing banner renderer.
- [x] Wire teaser overlay payload and frame draw invocation.
- [x] Verify build + focused teaser tests.
- [x] Create pre-change checkpoint commit before corner-parity refinement: `132921ed`.
- [x] Implement corner-parity refinement (per-corner path + body melt shape).
- [ ] Manual validation pending user teaser run.

## Code Change Ledger
- [x] `src/systems/TeaserRecorderHud.res`:
  - Added `marketingBannerData` model and `renderMarketingBanner` canvas renderer.
  - Implemented HD-reference-proportional sizing (font, paddings, segment height, max width) via existing HUD scaling model.
  - Implemented segment composition for `RENT`, `SALE`, and marketing body text.
  - Added text-fit fallback (ellipsis) to keep body text within computed banner width.
  - Added `drawRoundedRectCorners` helper for per-corner geometry control.
  - Updated segment drawing to round only outer top corners and keep middle segments flat.
  - Added body-segment lower melt capsule to mirror export text-wrap silhouette.
  - Revert note: remove `marketingBannerData`, `bannerSegment*` types, and `renderMarketingBanner`.
- [x] `src/systems/TeaserRecorder.res`:
  - Extended HUD overlay payload with `marketing` field.
  - Added alias `teaserMarketingOverlay = TeaserRecorderHud.marketingBannerData`.
  - Added marketing render invocation inside `renderFrame`.
  - Revert note: remove `marketing` overlay field, alias, helper call.
- [x] `src/systems/TeaserOfflineCfrRenderer.res`:
  - Added `marketingOverlayFromState` using `MarketingText.compose`.
  - Wired static marketing overlay payload into per-frame `sceneOverlayFor` output.
  - Revert note: remove marketing overlay function/wiring and `sceneOverlayFor` param.
- [x] Tests/build:
  - `npm run build`
  - `npm run test:frontend -- tests/unit/TeaserRecorder_v.test.bs.js`
  - `npm run test:frontend -- tests/unit/TeaserManager_v.test.bs.js`

## Rollback Check
- [ ] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
We are adding teaser marketing overlay rendering only, with HD-proportional geometry as the baseline contract. 
Implementation must preserve current teaser stability and avoid reintroducing previous timeout/abort regressions. 
All touched files are recorded above for surgical rollback if visual output is not accepted.

## Checkpoint
- Pre-corner-parity checkpoint commit: `132921ed` (`v4.15.2 [FAST]: pre teaser banner corner parity checkpoint`).
