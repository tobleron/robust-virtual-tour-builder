# Task: Backend SQLite Connection Pool Tuning & WAL Mode

## Objective
Configure SQLite for enterprise-grade concurrent access with WAL mode, connection pool sizing, busy timeout, and PRAGMA optimizations for the Actix-web backend.

## Problem Statement
`DatabaseManager::new()` in `backend/src/services/database.rs` creates a `SqlitePool` with default sqlx settings. Default SQLite operates in rollback journal mode which locks the entire database on writes, creating contention under concurrent uploads + saves + geocoding queries. No `busy_timeout`, no pool size limits, and no PRAGMA optimizations (synchronous, cache_size, mmap_size) are configured.

## Acceptance Criteria
- [x] Enable WAL (Write-Ahead Logging) mode via `PRAGMA journal_mode=WAL`
- [x] Set `PRAGMA busy_timeout=5000` to prevent immediate SQLITE_BUSY errors under contention
- [x] Set `PRAGMA synchronous=NORMAL` for WAL mode (safe compromise between safety and speed)
- [x] Set `PRAGMA cache_size=-64000` (64MB page cache)
- [x] Set `PRAGMA mmap_size=268435456` (256MB memory-mapped I/O for read-heavy workloads)
- [x] Configure pool: `min_connections=2`, `max_connections=10`, `idle_timeout=300s`, `max_lifetime=1800s`
- [x] Add connection pool health metrics as Prometheus gauges (`pool_size`, `pool_idle`, `pool_active`)
- [x] Add startup diagnostic log with effective pool and PRAGMA settings

## Technical Notes
- **Files**: `backend/src/services/database.rs`, `backend/src/metrics.rs`
- **Pattern**: Apply PRAGMAs via `sqlx::query("PRAGMA ...").execute(&pool)` post-migration
- **Risk**: Low — WAL mode is universally recommended for multi-reader SQLite; NORMAL sync is safe with WAL
- **Measurement**: Concurrent upload throughput improvement under 5 simultaneous sessions
