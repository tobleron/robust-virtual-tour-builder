# Task 049: Implement Session-Aware Save and Load in ProjectManager - REPORT

## Objective
Enable `ProjectManager` to communicate the `sessionId` between frontend and backend during save and load operations.

## Implementation Details

### Project Loading
- Updated `ProjectManager.processLoadedProjectData` to return a tuple `(sessionId, projectData)` instead of just `projectData`.
- Updated `loadProjectZip` and the `loadProject` wrapper to propagate this new return type.
- Updated `src/components/Sidebar.res` to destructure the new return result and dispatch `Actions.SetSessionId(sessionId)` before loading the project into state.

### Project Saving
- Updated `ProjectManager.createSavePackage` to extract the `sessionId` from the current application state.
- If a `sessionId` exists, it is now appended to the `FormData` as `"session_id"`. This allows the backend to identify that this project belongs to an existing session and can recover missing images from the session directory.

### Verification Results
- **Unit Tests**: Updated `tests/unit/ProjectManager_v.test.res` to account for the changed return signature of `processLoadedProjectData`. Verified that the `sessionId` is correctly returned and URLs are still properly reconstructed.
- **Frontend Integration**: Verified that the Sidebar correctly dispatches the session ID.

## Technical Realization
The frontend now proactively identifies itself to the backend during Save operations using the `session_id`. This completes the frontend portion of the "Session-Aware Save" architecture.
