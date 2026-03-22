# 1928 — Secure .env File from Version Control

**Priority:** 🔴 P0  
**Effort:** 10 minutes  
**Origin:** Codebase Analysis 2026-03-22

## Context

The root `.env` file contains sensitive dev credentials (`JWT_SECRET`, `SESSION_KEY`) and `BYPASS_AUTH=true`. It is **not listed in `.gitignore`**, meaning it could be (or already has been) committed to version history. This establishes a dangerous pattern where production credentials could accidentally be committed.

## Scope

### Steps

1. Add `.env` to `.gitignore` (root level)
2. Create `.env.example` with placeholder values:
   ```
   JWT_SECRET=your-jwt-secret-here-must-be-at-least-64-bytes
   SESSION_KEY=your-session-key-here-must-be-at-least-64-bytes
   BYPASS_AUTH=false
   NODE_ENV=development
   DATABASE_URL=sqlite://data/database.db
   STORAGE_PATH=./storage
   LOG_LEVEL=info
   LOG_DIR=./logs
   TEMP_DIR=./temp
   SESSIONS_DIR=./sessions
   ALLOW_DISK_CHECK_BYPASS=false
   CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
   ```
3. Remove `.env` from git tracking: `git rm --cached .env`
4. Verify `BYPASS_AUTH` in backend source is guarded by `NODE_ENV != production`
5. Update `DEVELOPERS_README.md` to mention `.env.example` setup step

## Acceptance Criteria

- [ ] `.env` is listed in `.gitignore`
- [ ] `.env.example` exists with safe placeholder values
- [ ] `.env` is not tracked by git (`git status` shows no `.env`)
- [ ] Developer documentation references `.env.example`
