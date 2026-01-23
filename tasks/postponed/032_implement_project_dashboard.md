# Task 032: Implement Project Management Dashboard (Control Panel)

**Priority**: High
**Effort**: Medium (10-12 hours)
**Impact**: High
**Category**: Frontend / UI

## Objective

Develop a "Control Panel" where users can view, delete, rename, and open their saved virtual tour projects. This transforms the app into a true multi-project platform.

## Requirements

### 1. Dashboard UI (`Dashboard.res`)
- A grid/list view of all user projects.
- Search and Filter functionality.
- "Project Card" components showing:
  - Project name and updated date.
  - A thumbnail preview (if available).
  - Status (Draft / Published).

### 2. Project Actions
- **Open**: Loads the project JSON and assets into the editor.
- **Delete**: Removes project from DB and assets from Storage.
- **Rename**: Quick inline edit for project titles.
- **Duplicate**: Create a copy of an existing project.

### 3. State Integration
- Fetch user projects on dashboard load.
- Handle loading states with skeletons or spinners.
- Empty state UI for new users ("You haven't created any tours yet").

## Implementation Steps

### Phase 1: Layout & Navigation
- Create a new route or view state for `/dashboard`.
- Build the layout with a sidebar or top-nav specifically for project management.

### Phase 2: Data Fetching
- Implement Supabase queries to fetch projects belonging to the current user.
- Map the JSONB `project_data` to the existing ReScript types.

### Phase 3: Project CRUD
- Implement the "Delete" confirmation modal.
- Implement the "Rename" logic.
- Ensure the editor can "Save" updates back to the specific Project ID in PostgreSQL.

## Success Criteria

- [ ] Dashboard displays a list of projects from the database.
- [ ] Users can navigate between the Dashboard and the Editor.
- [ ] Deleting a project correctly updates the UI and the database.
- [ ] "Open" correctly populates the `AppContext` with the project's data.
