# Project Evolution & Release History

This document tracks the iterative growth, version milestones, and long-term roadmap for the Robust Virtual Tour Builder.

---

## 🚀 Current Project Status
- **Version**: 4.14.0 (Commercial Ready)
- **ReScript Logic Coverage**: ~95%
- **Test Pass Rate**: 100% (Unit and E2E)
- **Architecture**: Complete Migration from JavaScript to a type-safe functional architecture, utilizing ReScript on the frontend and Rust on the backend.

---

## 📦 Version History

### v4.14.0: Commercial Readiness (2026-02-04)
- **Focus**: Expansion of E2E coverage and robustness hardening.
- **Key Changes**: 12 new E2E tests added covering Circuit Breakers, Rollbacks, Rate Limiting, and Interaction Queues.
- **Audit Findings**: 7.5/10 Commercial Grade Score; 100% Type Safety, Zero `unwrap()` calls.

### v4.3.7: "Stable UI No Ghost" (2026-01-21)
- **Focus**: Final resolution of "Ghost Arrow" artifacts.
- **Key Changes**: Implemented "Iron Dome" CSS protections and loop de-confliction.

### v4.3.0: Commercial Compliance (2026-01-15)
- **Focus**: Legal and SEO readiness.
- **Key Changes**: Addition of Privacy Policy, Terms of Service, and structured data headers.

### v4.0.0: ReScript Transition (Early 2026)
- **Focus**: Migration from JavaScript to a type-safe functional architecture.
- **Key Changes**: Complete rewrite of the logic layer; introduction of the Rust backend.

---

## 🛠️ Notable Refactoring Campaigns & System Audits

### Documentation Reorganization Analysis (2026-02-04)
- Reorganized fragmented documentation into a flat hierarchy.
- Established a prefix naming convention (`arch_`, `project_`, `guide_`, `policy_`).
- Merged redundant `_pending_integration` documents and completely archived 17 dead test output logs.

### Analysis: `_dev-system` Accuracy (2026-02-01)
- Configured complexity thresholds to align accurately with ReScript AST patterns.
- Downweighted syntactic sugar like `->` (0.05 -> 0.0) and standard functional flow like `switch` (0.8 -> 0.2) to prevent false positives in "Drag" scoring.

### Surgical Refactor Campaign: Tasks 1108, 1112-1114, 1116
- **Frontend**: Extracted core logic out of pure UI components into `*Logic.res` counterparts (`Simulation.res` -> `SimulationLogic.res`).
- **Backend**: Consolidated domains (merged `services/auth/` to `auth.rs`; created `pathfinder/` algorithms module).
- **CSS Cleanups**: Extracted monolithic `viewer.css` into smaller parts.
- **Map Enforcement**: Classified all modules cleanly in `MAP.md`.

---

## 🗺️ Strategic Roadmap

### Tier 1: Core Consolidation (COMPLETED)
- ✅ Centralized Reducer Architecture (ReScript).
- ✅ Rust-Powered Image Processing Pipeline.
- ✅ Robust State management via `RootReducer`.

### Tier 2: Refinement & Polish (CURRENT)
- 🏃 E2E Framework Migration (from time-based waits to event/state-driven waits).
- 🏃 Split `SidebarLogic.res` into localized modules (Upload, ProjectIO, Export, Progress).
- 🏃 Expand tests for the Export Runtime UX and define shortcut key handling.

### Tier 3: Advanced Intelligence (FUTURE)
- 🔮 AI-assisted scene categorization.
- 🔮 Deep image similarity for hotspot suggestions.
- 🔮 Interactive floor plan generation.
