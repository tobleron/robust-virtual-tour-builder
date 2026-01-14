---
description: Offload Project ZIP loading to Rust backend to solve memory issues
---

# Objective
Move the "Load Project" logic from the frontend (`src/systems/ProjectManager.res` using `JSZip`) to the Rust backend to prevent Out-Of-Memory (OOM) crashes with large tours (>1GB).

# Context
Currently, the browser reads the entire ZIP into memory, then `JSZip` extracts it into memory, and then creates Blobs for every image. This triples the memory usage. The backend should handle extraction and serve files via a local server.

# Requirements

1.  **Backend Implementation (`backend/src/handlers.rs`)**:
    *   Create a new endpoint `POST /import-project`.
    *   Accepts a raw file stream (Multipart or raw body).
    *   Streams the upload to a temp file.
    *   Unzips the content to `SESSIONS_DIR / {sessionId}`.
    *   Validates `project.json` exists.
    *   Returns `{ sessionId: string, projectData: json }`.

2.  **Frontend Implementation (`src/systems/ProjectManager.res`)**:
    *   Remove `JSZip` usage for loading.
    *   Implement `importProject(file)`:
        *   Uploads file to `/import-project`.
        *   Receives `sessionId` and `projectData`.
    *   **Asset URL Handling**:
        *   Instead of creating `Blob` URLs for images, construct URLs pointing to the backend: `http://localhost:SERVER_PORT/sessions/{sessionId}/images/{filename}`.
        *   Update `types.res` or `State` logic to handle string URLs instead of just Blobs (or wrap them transparently).

3.  **Cleanup**:
    *   Remove `libs/jszip.min.js` reference if no longer needed for Saving (Saving sends data to backend too, so JSZip shouldn't be needed there either if completely moved). *Note: Ensure Save also works without JSZip if that was the only consumer.*

4.  **Verification**:
    *   Load a massive tour (1GB+). Monitor browser memory. It should remain low.
    *   Verify images load correctly in the Viewer.
