# Migration Phase 3: Asset Persistence & Isolation

**Goal**: Move from transient `/tmp` storage to a structured, persistent local filesystem that isolates files by User ID.

## 📋 Requirements
1. **Persistent Root**: All assets must move to `./data/storage/`.
2. **Isolation**: Files must be stored at `{storage_root}/{user_id}/{project_id}/`.
3. **Consistency**: The `import` and `save` logic must be refactored to use this new path structure.

## 🛠️ Implementation Steps
1. **Storage Manager**:
   - Create `backend/src/services/media/storage.rs`.
   - Implement `get_user_project_path(user_id, project_id)` helper.
   - Implement logic to ensure directory existence on demand.
2. **Migration Logic**:
   - Refactor `backend/src/api/project/storage/mod.rs` (`import_project` and `save_project`).
   - Instead of unzipping to `/tmp/vt_sessions`, unzip directly to the persistent user-specific directory.
3. **Asset Serving Refactor**:
   - Update `backend/src/api/media/serve.rs`.
   - Change the route to `/api/project/{project_id}/file/{filename}`.
   - Middleware must verify that the requesting user owns the `project_id` before serving the file.
4. **Cleanup**:
   - Remove references to `SESSIONS_DIR` and `TEMP_DIR` in `utils.rs` once migration is verified.

## ✅ Success Criteria
- Uploaded images persist after server restart.
- User A cannot access User B's images even if they know the filename.
- The `./data/storage` directory mirrors the expected user/project hierarchy.
