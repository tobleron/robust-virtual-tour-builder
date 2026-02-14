# 1369 Refine Upload Scene Sorting Fallbacks

## Summary
- The upload processor currently orders newly added scenes using only the EXIF `dateTime` string. When multiple files lack EXIF timestamps the order is undefined, which leads to nondeterministic scene names.
- We want to add deterministic fallbacks so that uploads without EXIF metadata still produce a reasonable sort order before file names are assigned and clustering runs.

## Requirements
1. Update the sorting step in `src/systems/UploadProcessorLogic.res` so each processed `uploadItem` computes a ranking score in this priority:
   - Primary: EXIF `dateTime` (if present)
   - Secondary: numeric serial postfix parsed from the file name (e.g., `IMG_0123`, `PANO-004`, or any trailing digits separated by underscores/hyphens)
   - Tertiary: browser-provided `File.lastModified` timestamp (the best approximation of creation time available in the File API)
   - The comparator should remain stable so equal scores keep the original processing order.
2. If both EXIF and serial postfix are missing, use the `lastModified` value directly for sorting (but still keep the comparator deterministic by including an index fallback when `lastModified` ties happen).
3. Leave the existing filename assignment (`TourLogic.computeSceneFilename`) and clustering logic intact; only the sorting key changes.
4. Log a descriptive `Logger.debug` entry when the comparator uses a fallback (serial or lastModified) to aid future troubleshooting.
5. Keep any helper utilities pure and local to this module (unless a shared helper already exists). Avoid mutable state, keep `Option` usage explicit, and favor `JsonCombinators` for JSON decoding.

## Acceptance Criteria
- New comparator respects the 3-tier fallback order and remains stable.
- There is textual evidence (via `Logger.debug`) that fallback branches were evaluated.
- `npm run build` completes with zero warnings after the change.

## Notes
- Do not forget to move this task file to `tasks/active/` before implementation, and to `tasks/completed/1369_refine_upload_sorting_fallbacks_DONE.md` after everything is verified.
