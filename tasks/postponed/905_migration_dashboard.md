# Migration Phase 5: Commercial Dashboard & Custom Branding

**Goal**: Provide a professional workspace for users to manage their tours and customize their visual experience.

## 📋 Requirements
1. **Dashboard UI**: A grid view of the user's saved tours with thumbnails and metadata.
2. **Project Sync**: Automated "save-on-change" or a manual "Sync to Cloud" feature.
3. **Theme Switching**: Infrastructure for dynamic UI themes (Light/Dark/Branded).
4. **Metadata Enrichment**: Track project stats (scene count, hotspot count) in SQLite.

## 🛠️ Implementation Steps
1. **Dashboard Component**:
   - Create `src/components/dashboard/ProjectDashboard.res`.
   - Implement `GET /api/projects` to fetch the user's tour list.
2. **Theme Configuration System**:
   - Create `src/utils/ThemeConfig.res` to manage theme state.
   - Implement `[data-theme]` support in `css/variables.css`.
   - Add a theme toggle mechanism that persists to the user profile in SQLite.
3. **Synchronization Logic**:
   - Update `src/systems/ProjectManager.res` to send partial updates to the backend instead of full ZIPs where possible.
   - Implement `POST /api/project/{id}/sync` for lightweight JSON updates.
4. **Backend Enrichment**:
   - Refactor `backend/src/api/project/validation.rs` to update project statistics in the SQLite `projects` table upon every sync.
5. **Project Lifecycle**:
   - Implement "Rename Project" and "Delete Project" buttons in the Dashboard.

## ✅ Success Criteria
- User sees all their tours immediately after logging in.
- Projects can be loaded directly from the dashboard.
- Theme preference persists across page reloads and is synchronized with the backend.
- Database statistics (scene count) match the actual project state.