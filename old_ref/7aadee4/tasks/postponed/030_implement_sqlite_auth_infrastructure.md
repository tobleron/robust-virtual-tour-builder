# Task 030: Implement SQLite Persistence & Local Auth (Google + Email/Password)

**Priority**: High (Postponed)
**Effort**: Medium (10-12 hours)
**Impact**: Critical
**Category**: Infrastructure / Backend

## Objective

Replace the transient `/tmp` session storage with a robust, self-contained architecture using **SQLite** for metadata and a **Persistent Local Filesystem** for binary assets. Implement a flexible authentication system supporting both **Manual OAuth2 Google Login** and **Simple Email/Password Signup** to ensure the tool remains self-contained and usable without external providers.

## Current Status

**Storage Strategy**: Transient `/tmp` folders (data lost on restart).
**Risk**: Data loss. No ownership. High friction for repeat users.

## Implementation Steps

### Phase 1: Local Database Setup (SQLite)
1. Add `sqlx` (with `sqlite` and `runtime-tokio`) to `backend/Cargo.toml`.
2. Create a `database.db` file in a persistent `./data` directory.
3. Define the local schema:
   - `users`: `id`, `email`, `password_hash` (nullable for OAuth users), `google_id` (nullable), `name`, `avatar_url`, `created_at`.
   - `projects`: `id`, `user_id`, `name`, `status` (draft/published), `project_data` (JSON), `created_at`, `updated_at`.

### Phase 2: Local Storage Persistence
1. Create a `./data/storage` directory.
2. Update `ProjectManager.rs` and `Exporter.rs` to move processed images from `/tmp` to `./data/storage/{user_id}/{project_id}/`.
3. Implement a local file-serving route for these persistent assets.

### Phase 3: Authentication System
1. **Dependencies**: Add `oauth2`, `jsonwebtoken`, and `argon2` (for password hashing).
2. **Google OAuth2**:
   - `/api/auth/google/login`: Redirects user to Google Consent Screen.
   - `/api/auth/google/callback`: Exchanges code for token.
3. **Simple Auth (Email/Password)**:
   - `/api/auth/register`: Accepts email/password, hashes password, creates user.
   - `/api/auth/login`: Verifies password, issues JWT.
4. **Middleware**: Setup Auth Middleware to protect project routes.

### Phase 4: Sync Layer Logic
1. Implement `api/project/sync` to allow the frontend to save progress to SQLite.
2. Implement `api/dashboard` to list the user's saved tours.

## Success Criteria

- [x] Groundwork: SQLite database initialized with migrations.
- [x] Groundwork: Google OAuth2 and JWT dependencies added.
- [x] Groundwork: Database and Auth service skeletons implemented.
- [ ] User Setup: Provide `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.
- [ ] Implementation: Complete `google_callback` logic and JWT issuance.
- [ ] Implementation: Secure projects with Auth middleware.
- [ ] Implementation: Dashboard and Sync routes.
