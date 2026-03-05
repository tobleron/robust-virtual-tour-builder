# Task 1801: Observability: Health Dashboard & Metrics Aggregation

## 🤖 Agent Metadata
- **Assignee**: Antigravity (AI Agent)
- **Capacity Class**: B
- **Objective**: Create a unified health monitoring endpoint and dashboard UI.
- **Boundary**: `backend/src/api/health.rs`, `src/systems/Admin/`.
- **Owned Interfaces**: `/api/health` response schema.
- **No-Touch Zones**: Core auth logic.
- **Independent Verification**: 
  - [ ] `/api/health` returns aggregated status of DB, Cache, and Disk.
  - [ ] Admin dashboard displays health trends.
- **Depends On**: None

---

## 🛡️ Objective
Improve system visibility by aggregating health signals from all layers (Backend, SQLite, Geocoding Cache, Session Storage) into a single observability point.

---

## 🛠️ Execution Roadmap
1. **Aggregation Logic**: Update `backend/src/api/health.rs` to probe DB connectivity and cache disk usage.
2. **Metrics Pipeline**: Ensure Prometheus metrics for request latency and error rates are active.
3. **Admin UI**: Create a minimal internal-only health dashboard in the frontend.
4. **Alerting**: (Foundational) Log CRITICAL health failures to Sentry with a "system-health" tag.

---

## ✅ Acceptance Criteria
- [ ] `/api/health` returns `200 OK` only if DB and local disk are healthy.
- [ ] Dashboard shows active session counts.
- [ ] Cache hit/miss rates are visible.
