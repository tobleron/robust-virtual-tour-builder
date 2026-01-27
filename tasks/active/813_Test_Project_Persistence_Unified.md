# Task: 813 - Test: Project Management & Persistence Logic (New + Update)

## Objective
Verify project serialization, loading, saving, and state management.

## Merged Tasks
- 691_Test_ProjectData_Update.md
- 693_Test_ProjectManager_Update.md
- 772_Test_ProjectManagerLogic_New.md
- 773_Test_ProjectManagerTypes_New.md
- 661_Test_ProjectReducer_Update.md
- 647_Test_JsonTypes_Update.md
- 690_Test_PanoramaClusterer_Update.md

## Technical Context
Ensures that the user's work is correctly saved and loaded. Includes the complex logic for packaging/unpackaging projects.

## Implementation Plan
1. **ProjectManagerLogic**: Test the ZIP generation and parsing logic (mocking `JSZip`).
2. **ProjectData**: Verify JSON serialization/deserialization of the full state tree.
3. **Reducer**: Test project-level settings updates.
4. **Clusterer**: Test the logic that groups scenes based on visual/time timestamps.

## Verification Criteria
- [ ] Round-trip serialization (State -> JSON -> State) preserves data.
- [ ] ZIP export structure matches expectation.
