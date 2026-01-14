# Report: Frontend Single-ZIP Integration

## Objective (Completed)
Update the `ProjectManager.res` and `UploadProcessor.res` to consume the single-ZIP response from the updated `/load-project` endpoint.

## Context
Now that the backend returns a single ZIP, we need to stop making multiple fetch calls for images and instead extract them from the ZIP using `JSZip` or similar.

## Implementation Details

1. **Update `ProjectManager.res`**:
   - Update `loadProject` to handle `application/zip` response.
   - Use `JSZip` bindings (if not already present in `ReBindings.res`) to unzip the blob.
   - Parse `project.json` from the ZIP.
   - Extract images from the `images/` directory in the ZIP.

2. **Reconstruct File Objects**:
   - For each extracted image blob, create a new `File` object using the scene names.
   - Attach these `File` objects to the scene data before dispatching the state update.

3. **Handle Validation Report**:
   - Read the `validationReport` from the project JSON.
   - Use the `Notification` system to show a summary to the user (e.g., "Loaded project. 3 broken links cleaned.").

## Testing Checklist
- [x] Load a multi-scene project. Verify all images are displayed immediately.
- [x] Check Network tab: Confirm only ONE large request to `/load-project` happens instead of dozens of image fetches.
- [x] Verify scene names match the extracted filenames.

## Definition of Done
- Frontend successfully loads whole projects via single ZIP.
- No more N+1 requests observed in the browser.
- Validation warnings are displayed to the user.
