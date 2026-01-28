# Migration Phase 2: Identity & Security Layer

**Goal**: Implement industry-standard authentication and authorization using JWT and standard Actix middleware.

## 📋 Requirements
1. **Authentication**: Support for JWT (JSON Web Tokens) for stateless API authorization.
2. **Session Management**: Integration of `actix-session` for encrypted cookie handling.
3. **Middleware Layer**: A custom `AuthMiddleware` that intercepts requests, validates tokens, and injects the `User` identity into the request context.

## 🛠️ Implementation Steps
1. **Security Dependencies**: Add `jsonwebtoken` and `argon2` (for secure password hashing) to `backend/Cargo.toml`.
2. **JWT Implementation**:
   - Create `backend/src/services/auth/jwt.rs`.
   - Implement `encode_token` and `decode_token` with configurable expiration.
3. **Auth Middleware**:
   - Create `backend/src/middleware/auth.rs`.
   - Logic: Extract `Bearer` token from `Authorization` header -> Verify JWT -> Fetch user from DB -> Insert into `req.extensions()`.
4. **Session Integration**:
   - Configure `actix_session::SessionMiddleware` in `backend/src/main.rs`.
   - Use a secure, random `Key` for cookie encryption.
5. **Route Protection**:
   - Wrap project routes (Save, Load, Export) in the new `AuthMiddleware`.
   - Ensure the `/api/auth/` routes remain public.

## ✅ Success Criteria
- API returns `401 Unauthorized` when accessing protected routes without a token.
- Passwords stored in SQLite are hashed using Argon2 (never plain text).
- Unit tests verify that an expired JWT is rejected.
