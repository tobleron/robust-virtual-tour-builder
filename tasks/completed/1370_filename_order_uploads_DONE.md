# 1370 Simple Filename Ordering for Uploads

## Summary
- The recent EXIF/serial-based sorting logic introduced extra complexity and still surfaces uploads in an order that no longer matches the on-disk filenames.
- We want to simplify back to a filename-based ordering so that scenes appear sorted by their original file names before we assign the sequential scene filenames and run clustering.

## Requirements
1. Update `src/systems/UploadProcessorLogic.res` so that the `validProcessed` array is ordered alphabetically by each item's `File.name(item.original)` before `TourLogic.computeSceneFilename` runs.
2. Keep the scene renaming/clustering/finalization logic unchanged; only the ordering key should change.
3. If two files share the same name, preserve their original processing order (stable sort).
4. Remove any leftover EXIF/serial/lastModified helper code that is no longer needed.
5. Run `npm run build` after the change and ensure it succeeds without warnings.

## Acceptance Criteria
- The sorted list just before `createScenePayload` reflects alphabetical ordering by the original filename.
- Upload `npm run build` completes cleanly.

## Notes
- Preserve existing logging or add minimal notes only if helpful; the new comparator is intentionally straightforward.
- Follow the standard task workflow (move to `active/`, implement, run build, move to `completed/`).
