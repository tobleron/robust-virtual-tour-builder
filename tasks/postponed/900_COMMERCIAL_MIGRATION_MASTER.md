# MASTER PLAN: Commercial-Grade Migration (v1.0)

**Architect**: Gemini Agent (Principal SE Mode)
**Objective**: Transition the "Robust Virtual Tour Builder" from a `/tmp`-based prototype to a secure, persistent, and high-quality commercial application.

## 📌 Context
This migration replaces transient session hacks with standardized persistence, identity management, and professional-grade quality assurance. Every legacy postponed task (from SEO to E2E testing) has been surgically integrated into these six phases.

## 🛤️ Migration Phases

| Phase | Task ID | Focus | Legacy Integration | Status |
| :--- | :--- | :--- | :--- | :--- |
| **1** | [901](./901_migration_foundation.md) | SQLite, SQLx, and Schema Foundation | 030 (DB), 003 (SEO robots) | Pending |
| **2** | [902](./902_migration_security.md) | JWT, Sessions, and Identity Middleware | 033 (JWT Logic) | Pending |
| **3** | [903](./903_migration_storage.md) | User-Isolated Persistent Storage | Storage Isolation Recommendations | Pending |
| **4** | [904](./904_migration_frontend_auth.md) | Auth UI, Legal & i18n | 031 (Auth UI), 015 (Legal), 025 (i18n) | Pending |
| **5** | [905](./905_migration_telemetry.md) | Hardening, Quality & E2E | 022 (Shield), 024/800 (E2E), 020 (Visual), 004/006 (Docs) | Pending |

## 🛠️ Design Principles
1. **Stateless Backend**: The server must not rely on local `/tmp` state.
2. **Identity-First**: No project operation should happen without a verified User Identity.
3. **Type-Safety**: Enforce strict contracts via `rescript-schema`.
4. **Zero-Blindness Troubleshooting**: Maximum trace-level logging during and after migration.

## 🚀 Execution
Jules should pick up these tasks sequentially. Each phase must be fully verified (tests + build) before proceeding to the next.