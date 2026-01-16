# Task 157 Report: Add Tests for ServerTeaser

## Objective
Create unit tests for `src/systems/ServerTeaser.res` to verify request generation logic.

## Implementation Verified
1.  **Request Generation**: Verified that `generateServerTeaser` creates a valid `FormData` object with:
    -   `project_data` (serialized state)
    -   `width` and `height` parameters
    -   File attachments for scenes
2.  **API Call**: Verified that `fetch` is called with the correct URL (`/generate-teaser`) and method.
3.  **Mocking**: Implemented global mocks for `FormData` and `fetch` (via `%raw`) to intercept and validate calls without network requests.
4.  **Integration**: Registered `ServerTeaserTest` in `tests/TestRunner.res`.

## Results
-   Created `tests/unit/ServerTeaserTest.res` with mocked environment.
-   All assertions passed:
    -   Fetch called exactly once.
    -   Fetch URL matches configuration.
    -   FormData parameters are correct.
    -   Scene files are correctly appended.
-   `npm run test:frontend` passed successfully.
