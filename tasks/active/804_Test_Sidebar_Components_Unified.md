# Task: 804 - Test: Sidebar & Project HUD Components (New + Update)

## Objective
Verify the sidebar UI orchestration, project metadata inputs, and processing status indicators.

## Merged Tasks
- 754_Test_SidebarMain_New.md
- 786_Test_SidebarMainLogic_New.md
- 787_Test_SidebarMainTypes_New.md
- 751_Test_SidebarActions_New.md
- 752_Test_SidebarBranding_New.md
- 755_Test_SidebarProcessing_New.md
- 756_Test_SidebarProjectInfo_New.md
- 629_Test_Sidebar_Update.md

## Technical Context
The Sidebar is a complex React tree. Grouping these allows testing the flow from user action (ProjectInfo input) to logic processing (SidebarMainLogic) and back to UI (SidebarProcessing).

## Implementation Plan
1. **SidebarMainLogic**: Verify project name updates and upload triggers.
2. **UI Components**: Test `SidebarActions` dispatching correct events.
3. **Processing Overlay**: Verify progress bar mapping from state to UI.
4. **Sidebar Facade**: Ensure `SidebarMain.res` correctly mounts all sub-sections.

## Verification Criteria
- [ ] Component tests pass for all 5+ sidebar sub-modules.
- [ ] Input changes in `ProjectInfo` correctly update state in tests.
- [ ] Responsive states (collapsed/expanded) are verified.
