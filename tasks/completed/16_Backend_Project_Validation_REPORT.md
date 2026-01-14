# Report: Backend Project Validation Integration

## Objective (Completed)
Ensure the backend validation logic is fully integrated into the project saving and loading flows, providing a detailed `ValidationReport` to the frontend.

## Context
We have `validate_and_clean_project` in `handlers.rs`, but we need to ensure it's used consistently and that the report is actionable for the user.

## Implementation Details

1. **Integrate into `/save-project`**:
   - Before writing the project data to the session directory, run validation.
   - Return the `ValidationReport` in the JSON response.

2. **Integrate into `/load-project`**:
   - Run validation on the uploaded `project.json`.
   - Embed the `ValidationReport` into the `project.json` inside the returned ZIP or in the response headers/JSON.

3. **Expand Validation Rules**:
   - Detect **orphaned scenes**: Scenes that have no incoming links (except for the first scene).
   - Detect **duplicate link IDs**: Ensure `linkId` is unique within each scene.
   - Detect **missing metadata**: Flags scenes without categories or floors.

## Testing Checklist
- [x] Upload project with orphaned scene. Confirm report mentions it.
- [x] Save project with broken hotspot. Confirm it is auto-cleaned on the server.
- [x] Verify `ValidationReport` structure is correctly serialized (camelCase).

## Definition of Done
- Backend validation is triggered on every load/save.
- Front-end receives a clean `ValidationReport`.
- Broken links are automatically removed server-side.
