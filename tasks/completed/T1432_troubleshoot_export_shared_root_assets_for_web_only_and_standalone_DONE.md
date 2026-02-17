# T1432 - Troubleshoot Export Architecture: Shared Root Assets for Web-Only and Standalone

## Objective
Refactor export package structure so scene image assets are shared at ZIP root and usable by both `web_only` and `standalone` outputs, removing dependency on `web_only` image folders for standalone delivery.

## Target Architecture
- Place scene images in common root path:
  - `assets/images/4k/...`
  - `assets/images/2k/...`
  - `assets/images/hd/...`
- Keep launcher and both variant folders (`web_only`, `standalone`).
- Ensure each resolution HTML under both variants points to the shared root assets using correct relative paths.

## Hypothesis (Ordered Expected Solutions)
- [x] Current backend package writer stores scene images only under `web_only` tree.
- [x] Standalone currently depends on HTML data-URI rewrite instead of file-based shared assets.
- [x] Rewriting `assets/images/...` references per resolution to `../../assets/images/<res>/...` and writing shared root files will satisfy both variants.

## Activity Log
- [x] Inspect backend export package writer.
- [x] Implement shared root scene-asset writing.
- [x] Implement resolution-aware HTML path rewrite for both variants.
- [x] Remove obsolete standalone data-URI replacement path.
- [x] Verify build.

## Code Change Ledger
- [x] `backend/src/services/project/package.rs` - replace standalone data-URI strategy with shared root assets and deterministic per-resolution path rewrites.

## Rollback Check
- [x] Confirmed CLEAN or REVERTED non-working changes.

## Context Handoff
Standalone currently does not include file-based scene image assets and relies on transformed HTML behavior, while web_only stores image files under its own subtree. The requested architecture requires common root-level assets consumable by both output variants so standalone can be shared independently of web_only internals. Implementation should preserve existing folder entry points while centralizing image binaries.
