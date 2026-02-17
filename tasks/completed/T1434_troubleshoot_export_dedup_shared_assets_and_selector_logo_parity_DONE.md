# T1434 - Troubleshoot Export Dedup: Shared Assets + Selector Logo Parity

## Objective
Optimize export architecture by reducing duplicated asset folders and aligning selector-page logo placement/style with viewer HUD behavior.

## Target Outcome
- Single shared root for libraries and logo assets.
- Shared root image hierarchy remains resolution-aware (`assets/images/4k|2k|hd`).
- Selector page logo appears in viewer-like style at bottom-right.

## Hypothesis (Ordered Expected Solutions)
- [x] Current backend package writer duplicates `libs` and logo across variant/resolution folders unnecessarily.
- [x] Centralizing `libs/` and `assets/logo/` at root with relative path updates is safe for both `web_only` and `standalone` pages.
- [x] Export selector template currently places branding away from desired viewer-like position and needs CSS/layout parity updates.

## Activity Log
- [x] Inspect packaging writer for duplicated logo/lib writes.
- [x] Refactor package output paths to root-shared `libs` + `assets/logo`.
- [x] Update tour html template references to root-shared libs/logo.
- [x] Update selector html logo path and styling to bottom-right viewer-like card.
- [x] Verify build and backend compile.

## Code Change Ledger
- [x] `backend/src/services/project/package.rs` - deduplicate root-shared libs/logo writes and preserve compatibility with existing tour HTML generation.
- [x] `src/systems/TourTemplates.res` - update path references and selector-page logo layout/styling.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Export structure currently duplicates branding and dependency files across variant and resolution directories, increasing package size and maintenance friction. A root-shared model keeps only one copy of common assets while preserving resolution-specific images and standalone compatibility constraints. Selector page branding should visually align with viewer HUD and anchor bottom-right for consistent UX.
