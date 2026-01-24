# Task 033: Secure Rust Backend with JWT Verification

**Priority**: High
**Effort**: Medium (6-8 hours)
**Impact**: Critical
**Category**: Backend / Security

## Objective

Secure the Rust API endpoints so that they only accept requests from authenticated users. The backend must verify the Supabase JWT token before allowing operations like "Save" or "Generate Teaser."

## Requirements

### 1. JWT Middleware
Create a middleware in `backend/src/middleware/auth.rs` that:
- Extracts the `Authorization: Bearer <token>` header.
- Verifies the signature against the Supabase JWT Secret.
- Extracts the `sub` (User ID) from the token claims.

### 2. Secure Route Scopes
Group user-specific routes under an authenticated scope:
- `POST /api/project/save`
- `GET /api/projects`
- `DELETE /api/project/{id}`

### 3. Ownership Validation
Ensure that when a user tries to modify a project, the backend checks if the `user_id` in the database matches the `user_id` in the JWT.

## Implementation Steps

### Phase 1: Dependency Setup
Add `jsonwebtoken` and `serde` support to `backend/Cargo.toml`.

### Phase 2: Implementation of Validator
- Create a `Claims` struct for decoding the Supabase token.
- Implement the validation logic using the `SUPABASE_JWT_SECRET`.

### Phase 3: Actix-Web Integration
- Apply the middleware to the relevant Actix scopes in `main.rs`.
- Update handler functions to receive the `User` object or `UserId` from the request extensions.

## Success Criteria

- [ ] Backend rejects requests without a valid token (401 Unauthorized).
- [ ] Backend allows valid Supabase tokens.
- [ ] Backend correctly identifies the User ID from the token for data queries.
- [ ] Automated tests verify that User A cannot delete User B's project.
