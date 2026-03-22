# 1936 — Sync Backend Cargo.toml Version with Frontend

**Priority:** 🟡 P2  
**Effort:** 5 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

Version drift exists between the frontend and backend:
- `package.json` → `"version": "5.3.8"`
- `backend/Cargo.toml` → `version = "0.1.0"`

The backend version appears to have never been updated from the initial template. This matters for:
- Deployment tracing and incident debugging
- Health endpoint version reporting
- Sentry error grouping and release tracking
- Build artifact identification

## Scope

### Steps

1. Update `backend/Cargo.toml` version to match `package.json`:
   ```toml
   version = "5.3.8"
   ```
2. If the backend health endpoint reports a version, verify it uses `Cargo.toml`'s value
3. Consider adding the backend version sync to the existing `version-sync` npm script:
   ```bash
   # scripts/update-version.js should also update Cargo.toml
   ```
4. Run `cd backend && cargo build` to verify

## Acceptance Criteria

- [ ] `backend/Cargo.toml` version matches `package.json` version
- [ ] `cd backend && cargo build` passes
- [ ] (Optional) Version sync script handles both `package.json` and `Cargo.toml`
