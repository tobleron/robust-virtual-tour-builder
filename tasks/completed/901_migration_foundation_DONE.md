# Migration Phase 1: Persistent Data Foundation

**Goal**: Establish a relational database layer to replace manual JSON file management and transient session tracking.

## 📋 Requirements
1. **Database Engine**: SQLite (via `sqlx`) for a self-contained, high-performance local store.
2. **Schema Definition**:
   - `users`: `id` (UUID), `email` (unique), `password_hash`, `name`, `theme_preference`, `language_preference`, `created_at`.
   - `projects`: `id` (UUID), `user_id` (FK), `name`, `data` (JSONB/Text), `status`, `scene_count`, `hotspot_count`, `updated_at`.
   - `sessions`: `id`, `user_id`, `expires_at` (for server-side session tracking).
3. **SEO & Discovery Foundation**: Include `robots.txt` and base structured data configuration.

## 🛠️ Implementation Steps
1. **Dependency Audit**: Ensure `sqlx` with `sqlite` and `runtime-tokio` features is properly configured in `backend/Cargo.toml`.
2. **Migration Infrastructure**: 
   - Verify `backend/migrations/` structure.
   - Create a new migration file: `20260128000000_core_schema.sql`.
   - Implement the tables mentioned above with proper foreign key constraints.
3. **Database Service**:
   - Refactor `backend/src/services/database.rs` to provide a thread-safe `SqlitePool` via `web::Data`.
   - Implement an automated migration runner on server startup.
4. **Repository Pattern**:
   - Create `backend/src/models/user.rs` and `backend/src/models/project.rs` structs matching the schema.
   - Implement basic CRUD functions (Create User, Get User by Email, Save Project).
5. **Base SEO Setup**:
   - Create `public/robots.txt` to manage crawlability.
   - Add `WebApplication` structured data (JSON-LD) to `index.html`.

## ✅ Success Criteria
- Backend starts without errors and successfully runs migrations.
- `database.db` is created in the `./data` directory.
- Basic unit tests verify that a user can be inserted and retrieved from SQLite.
- `robots.txt` is accessible at `/robots.txt`.