# Task 1809: Infrastructure: PostgreSQL Enterprise Migration Path

## 🛡️ Objective
Prepare the backend for multi-node scaling by defining and testing the migration path from local SQLite to PostgreSQL.

---

## 🛠️ Execution Roadmap
1. **Cargo Config**: Add `postgres` feature to `sqlx` in `Cargo.toml`.
2. **Pool Abstraction**: Refactor `Pool<Sqlite>` to a generic database pool or use `AnyPool`.
3. **SQL Audit**: Audit existing SQL queries for SQLite-specific syntax (e.g., `REPLACE INTO`).
4. **Docker**: Add a `docker-compose.yml` for local PostgreSQL testing.

---

## ✅ Acceptance Criteria
- [ ] Backend can compile and run against a PostgreSQL instance (opt-in via ENV).
- [ ] Documentation for the migration procedure is complete.
