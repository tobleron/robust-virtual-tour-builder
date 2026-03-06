# Task 1805: Backend: Database Migration System (sqlx-migrate)

## 🛡️ Objective
Implement a formal migration system for the SQLite database to track schema changes version-by-version, replacing manual DB updates.

---

## 🛠️ Execution Roadmap
1. **Setup**: Initialize `migrations/` folder in the backend.
2. **Current Schema**: Extract the existing schema into `001_initial_schema.sql`.
3. **App Integration**: Update `startup.rs` to run `sqlx::migrate!().run(&pool).await?` on startup.
4. **CI Verification**: Ensure CI runs migrations against a temporary DB during the test phase.

---

## ✅ Acceptance Criteria
- [ ] Server refuses to start if migrations fail.
- [ ] Schema is version-controlled in the repository.
