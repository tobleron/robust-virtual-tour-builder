# Task: Create Unified Backend API Module

## Objective
Create a single ReScript module `BackendApi.res` that handles all HTTP requests to the Rust backend with standardized error handling and type-safe payloads.

## Context
Currently, `fetch` calls are scattered across `ProjectManager`, `Resizer`, `Exporter`, etc. A unified module reduces duplication and makes it easier to update the `BACKEND_URL` or authentication logic in one place.

## Implementation Steps

1. **Create `BackendApi.res`**:
   - Define a `Result` type for API responses.
   - Implement `postMultipart`, `postJson`, and `get` helpers.
   - Standardize error parsing for the backend's `ErrorResponse` struct.

2. **Centralize Endpoints**:
   - Create functions for `/process-image-full`, `/load-project`, `/save-project`, etc.
   - Use these functions in all other ReScript modules.

3. **Handle Timeouts**:
   - Implement a default timeout logic (e.g. 5 minutes for large project uploads).

## Testing Checklist
- [x] All major actions (Upload, Save, Load) still work via the new module.
- [x] Check console: confirm only the `BackendApi` module is logging fetch errors.
- [x] Verify error modals show the specific "details" string from the Rust backend.

## Definition of Done
- `BackendApi.res` exists and is the only place calling `fetch`.
- Codebase is significantly cleaner and more type-safe.
