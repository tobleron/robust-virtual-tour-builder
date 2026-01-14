# Report: Backend Single-ZIP Load Implementation

## Objective (Completed)
Modify the `/load-project` backend endpoint to return a single ZIP archive containing the `project.json` and all associated scene images, instead of requiring multiple follow-up requests.

## Context
Currently, the frontend fetches `project.json`, then manually iterates through scenes and makes N+1 HTTP requests to fetch image blobs. This is slow and hits browser connection limits.

## Implementation Details

1. **Modify `backend/src/handlers.rs`**:
   - Update `pub async fn load_project` to correctly handle the multipart upload of the project ZIP.
   - (Verification): It already seems to have some of this logic, but ensure it captures ALL images from the uploaded ZIP or session directory.
   - Ensure the response `Content-Type` is set to `application/zip`.
   - The ZIP should contain:
     - `project.json` (at root)
     - `images/` folder containing all `.webp` panoramas.

2. **Integration with Validation**:
   - Ensure `validate_and_clean_project` is called *before* packaging the ZIP.
   - The `project.json` inside the ZIP must be the *validated* version.

3. **Error Handling**:
   - Handle cases where images are missing from the uploaded ZIP.
   - Return clear `AppError::ZipError` if bundling fails.

## Testing Checklist
- [x] Direct API Test: `curl -X POST -F "file=@project.zip" http://localhost:8080/load-project` returns a ZIP.
- [x] Validation: Upload a ZIP with a broken link (hotspot target that doesn't exist). Confirm the `project.json` in the response ZIP has the link removed.
- [x] Performance: Measure time to load a project with 50 scenes. Target < 5s.

## Definition of Done
- `/load-project` returns a single ZIP file.
- The ZIP contains a valid `project.json`.
- All scene images are present in the ZIP.
