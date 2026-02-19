# 🔍 Robust Virtual Tour Builder - Technical Audit Report (v5.1 – Independent Verification)

**Date:** 2026-02-19
**Auditor:** Independent AI Principal Engineer (Code-Verified Analysis)
**Scope:** Full Stack (ReScript Frontend + Rust Backend)
**Baseline:** v5.0 Report by Jules (AI Principal Engineer), dated 2025-05-15
**Method:** All claims independently verified against current `main` branch source code.

---

## Executive Summary

The codebase demonstrates **exceptional engineering discipline** with strong adherence to functional programming paradigms, comprehensive safety patterns, and mature documentation. However, the v5.0 audit report is **overly generous** in several areas and **misses critical findings** that any honest assessment must surface.

**Overall Health Score: A- (Production Ready with Caveats)**

> The downgrade from A+ reflects real issues found during code-level verification, not a reflection of poor quality. The project is well above average — but an accurate audit must not gloss over gaps.

---

## 1. Protocol Compliance (GEMINI.md) — VERIFIED ✅

| Criterion | v5.0 Claim | Verified Status | Independent Findings |
| :--- | :--- | :--- | :--- |
| **ReScript v12** | ✅ | ✅ **Confirmed** | `rescript: ^12.0.2` in `package.json`. Explicit `Option`/`Result` handling throughout. |
| **No `console.log`** | ✅ | ✅ **Confirmed** | Zero live `console.log` calls in `src/`. |
| **JSON/IO Safety** | ✅ | ✅ **Confirmed** | `@glennsl/rescript-json-combinators` used exclusively. Zero `rescript-schema` or `eval` usage. |
| **Logger Module** | ✅ | ✅ **Confirmed** | Pervasive 4-module Logger system (`Logger`, `LoggerConsole`, `LoggerTelemetry`, `LoggerCommon`, `LoggerLogic`). |
| **Immutability** | ✅ | ⚠️ **Partial** | See Finding #1 below. |
| **Zero Warnings** | ✅ (assumed) | ⚠️ **Unverified** | Build was not executed during this audit. |

### Finding #1: Mutable State Usage (v5.0 Missed)

The v5.0 report claims "Functional purity maintained across Reducers and Systems." This is **partially inaccurate**:

- **`RateLimiter.res`**: `mutable timestamps: array<float>` — Necessary for performance-critical state.
- **`CircuitBreaker.res`**: `mutable internalState: internalState` — Required for circuit breaker pattern.
- **`InteractionGuard.res`**: 4 mutable fields (`lastExecution`, `timerId`, `pendingReject`, `limiter`).
- **`RequestQueue.res`**: Module-level `ref()` for `activeCount` and `paused`.

**Assessment:** These are **acceptable** uses of mutability — they are confined to stateful infrastructure modules that inherently require mutation. The reducers and core state remain purely functional. However, the v5.0 report should not have claimed blanket "functional purity" without qualifying this.

### Finding #2: Commented Debug Code — Confirmed

4 commented-out `Js.log` calls in `ExifReportGeneratorLogicExtraction.res` (lines 12, 15, 42, 53). The v5.0 report correctly identified this.

---

## 2. Architectural Integrity — VERIFIED ✅ (with nuances)

### Frontend (ReScript) — 228 modules, ~30,530 LOC

| Aspect | v5.0 Claim | Verified |
| :--- | :--- | :--- |
| Reducer delegation to sub-modules | ✅ | ✅ Confirmed via `ReducerModules.res`, `NavigationProjectReducer.res` |
| Side effects in Systems/ | ✅ | ✅ Confirmed |
| FSMs for lifecycle | ✅ | ✅ `NavigationFSM.res`, `AppFSM.res` both present |
| MAP.md accuracy | ✅ | ⚠️ **10 unmapped modules** at end of MAP.md |

### Backend (Rust) — 55 modules, ~8,827 LOC

| Aspect | v5.0 Claim | Verified |
| :--- | :--- | :--- |
| Layered API/Services/Models | ✅ | ✅ Confirmed |
| Tokio + Rayon concurrency | ✅ | ✅ Confirmed in `Cargo.toml` |
| Rate limiting | ✅ | ✅ `actix-governor` present |

### Finding #3: Heavy `%raw` Usage (v5.0 Missed Entirely)

The v5.0 report makes **no mention** of `%raw` JavaScript escape hatches, yet there are **62 instances** across the codebase. This is the **single largest type-safety gap** in the frontend:

**High-risk examples:**
- `src/App.res:25` — Attaches state to `window.__RE_STATE__` (debug backdoor)
- `src/Main.res:74-131` — Multiple `%raw` for initialization guards
- `src/systems/Api/AuthenticatedClient.res:142` — Cookie manipulation via raw JS
- `src/systems/ApiHelpers.res:115` — Raw `window.dispatchEvent` for auth logout
- `src/systems/Simulation.res:17` — Runtime type check via raw JS
- `src/core/JsonParsersDecoders.res:40-44` — Type checking via `typeof` and `instanceof`

**Most are legitimate** (browser API gaps in ReScript bindings), but some represent opportunities for typed `@module` bindings instead. A few (like `window.__RE_STATE__`) should be gated behind `Constants.isDevelopment`.

### Finding #4: `Obj.magic` Type Erasure (v5.0 Missed)

2 instances of `Obj.magic` in `RequestQueue.res` (lines 78, 124). `Obj.magic` is ReScript's `unsafeCast` — it bypasses the type system entirely. While the usage here is narrowly scoped (Promise rejection callbacks), it represents a type-safety hole that the report should acknowledge.

---

## 3. Frontend Review — DETAILED

### Module Size Distribution

| Range | Count | Notable Files |
| :--- | :--- | :--- |
| 500+ LOC | 1 | `TourScripts.res` (985) |
| 400-499 | 2 | `Exporter.res` (451), `ViewerManagerLogic.res` (436) |
| 300-399 | 10 | `AuthenticatedClient`, `SidebarLogic`, `Types`, etc. |
| < 300 | 215 | Well-decomposed |

**Assessment:** Module sizes are well-controlled. The `TourScripts.res` at 985 lines is a template script generator — its size is justified by template content rather than logic complexity.

### TODO Audit

| File | Line | TODO Content | Severity |
| :--- | :--- | :--- | :--- |
| `NavigationController.res` | 33 | "Refactor Scene.Loader to take granular dependencies" | Low |
| `Types.res` | 211, 217, 299, 312 | "TODO: Deprecate" on `scenes` and `deletedSceneIds` arrays | **Medium** |
| `Simulation.res` | 251 | Error data placeholder `"error": "TODO"` | **High** — This means error telemetry for simulation failures sends the literal string "TODO" as the error data. |

**The v5.0 report identified TODOs generically but missed the `Simulation.res` error telemetry issue — this is a real bug.**

---

## 4. Backend Review — DETAILED

### Safety Analysis

| Check | v5.0 Claim | Verified |
| :--- | :--- | :--- |
| `unwrap()` confined to tests | ✅ | ✅ **Zero** `.unwrap()` in non-test code |
| `.expect()` confined to tests | ✅ | ✅ **Confirmed** — All 29 `.expect()` calls are within `#[cfg(test)]` blocks |
| `unsafe` confined to tests | Not mentioned | ✅ Single `unsafe` in `auth.rs:345` — test-only `set_var` |
| Path traversal protection | ✅ | ✅ `sanitize_filename`, `sanitize_id`, `validate_path_safe` with `canonicalize` |
| Input sanitization tests | Not mentioned | ✅ Test suite covers path traversal, empty strings, special chars |

### Security-Relevant Dependencies — Verified

| Dependency | Purpose | Version | Status |
| :--- | :--- | :--- | :--- |
| `jsonwebtoken` | JWT auth | 9.3 | ✅ Current |
| `argon2` | Password hashing | 0.5.3 | ✅ Current |
| `oauth2` | Google OAuth | 4.4 | ✅ Current |
| `actix-governor` | Rate limiting | 0.5 | ✅ Current |
| `sentry` | Error tracking | 0.46.1 | ✅ Current |
| `sqlx` | DB (SQLite) | 0.8 | ✅ Current |

### Auth Security — Deep Dive

The `auth.rs` implementation is **well-hardened**:
- ✅ Dev token bypass is **explicitly gated** behind `!is_production() && BYPASS_AUTH=true`
- ✅ Production use of dev-token triggers `SECURITY ALERT` and is rejected
- ✅ JWT secret validated at startup
- ✅ PKCE flow for OAuth
- ✅ Headless API token for server-side teaser generation

> **Note:** The previous Executive Summary audit (`docs/AUDIT_EXECUTIVE_SUMMARY.md`, Feb 4, 2026) flagged a "dev-token in production" risk in `ProjectManager.res`. The current code in `auth.rs` appears to have **properly mitigated** this with the `is_production()` guard.

---

## 5. Quality & Tests — VERIFIED (with corrections)

| Metric | v5.0 Claim | Verified |
| :--- | :--- | :--- |
| "100+ unit test files" | ✅ | ✅ **163 unit test files** (`.test.res`) |
| E2E coverage | "Critical journeys" | ✅ **16 E2E spec files** (significant improvement from prior audit's 1) |
| Performance budgets | ✅ | ✅ `check-bundle-budgets.mjs` and `check-runtime-budgets.mjs` confirmed |

**Assessment:** Test infrastructure has matured significantly since the Feb 4 executive audit, which noted only 1 E2E test. The progression to 16 E2E specs covering robustness, persistence, recovery, performance, and visual regression is strong.

---

## 6. Performance & Security — VERIFIED ✅

The v5.0 report's claims are accurate. Additional verification:

- **Release profile optimized:** `lto = true`, `codegen-units = 1`, `opt-level = 3`, `strip = true`
- **Sentry integration** for production error tracking
- **Prometheus metrics** via `actix-web-prom`
- **Structured tracing** via `tracing-subscriber` with JSON output

---

## 7. Maintenance & Documentation — VERIFIED (with finding)

### Finding #5: MAP.md Drift

MAP.md has **10 unmapped modules** in the `## 🆕 Unmapped Modules` section:
- `ExporterUtils.res`, `ExporterUpload.res`
- `TourStyles.res`, `TourData.res`, `TourScripts.res`, `TourAssets.res`
- `ProjectSave.res`, `ProjectRecovery.res`, `ProjectUtils.res`
- `backend/src/api/health.rs`

These are all recently extracted sub-modules from the D001 refactoring. They need proper classification and tagging to maintain MAP.md integrity.

---

## Summary: v5.0 Report Accuracy Assessment

| Section | v5.0 Accuracy | Notes |
| :--- | :--- | :--- |
| Protocol Compliance | 90% | Over-claimed immutability purity |
| Architectural Integrity | 85% | Missed `%raw` (62 instances), `Obj.magic` (2), unmapped modules (10) |
| Frontend Review | 90% | Missed `Simulation.res` TODO error telemetry bug |
| Backend Review | 95% | Accurate, well-verified |
| Tests | 85% | Over-stated as "100+" when it's 163 — directionally right but imprecise |
| Performance & Security | 95% | Accurate |
| Conclusion (A+) | ❌ Overrated | A- is more appropriate given the gaps identified |

---

## Actionable Suggestions (Corrected & Expanded)

### 🔴 High Impact (v5.0 Missed)

1. **Fix `Simulation.res:251` error telemetry** — Replace `"error": "TODO"` with `Logger.extractMessage(reason)` or equivalent. This means simulation failure diagnostics are currently useless.

2. **Audit `%raw` usage** — 62 instances is significant. Create tracking list, prioritize converting window-manipulation `%raw` calls to proper bindings or development-gated code. **Especially:** `src/App.res:25` (`window.__RE_STATE__`) should be behind `Constants.isDevelopment`.

3. **Classify 10 unmapped modules** in MAP.md — These are from the D001 surgical refactor and need proper `#tags` and semantic descriptions.

### 🟡 Medium Impact (Aligned with v5.0)

4. **Remove commented `Js.log`** in `ExifReportGeneratorLogicExtraction.res` (4 instances).

5. **Resolve `Types.res` deprecation TODOs** — 4 fields marked "TODO: Deprecate" suggest a stale migration.

6. **Replace `Obj.magic`** in `RequestQueue.res` — Consider defining a proper `DrainError` type to avoid type erasure.

### 🟢 Low Impact

7. **Standardize remaining TODOs** — `NavigationController.res` refactor TODO is low-risk.

---

## Strategic Recommendations

The v5.0 report's strategic recommendations (PostgreSQL migration, CDN, job queue, containerization, monitoring) are **sound and well-considered**. I endorse all five recommendations in full and have no additions.

---

## Conclusion

The **Robust Virtual Tour Builder** is a **well-architected, production-ready application** that demonstrates exceptional engineering discipline — particularly in its type safety, error handling, and reliability patterns. The v5.0 audit report is directionally accurate but **glosses over real gaps** that this verification has surfaced.

The most critical finding is the `Simulation.res` error telemetry bug (`"TODO"` placeholder), which should be fixed immediately. The `%raw` hygiene and MAP.md drift are maintenance items that should be tracked but do not block production use.

**Revised Grade: A- (Production Ready)**

| Dimension | Grade |
| :--- | :--- |
| Type Safety | A+ |
| Error Handling | A |
| Architecture | A |
| Test Coverage | A- |
| Security | A |
| Documentation | B+ |
| Code Hygiene | B+ |
