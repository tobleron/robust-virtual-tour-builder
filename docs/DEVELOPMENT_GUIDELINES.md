# Development Guidelines & Workflow Manual

This document outlines the protocols, standards, and automated workflows required for contributing to the Robust Virtual Tour Builder.

---

## 1. Core Development Pillars

### Type Safety & Functional Principles
- **ReScript/Rust First**: All new logic must be written in ReScript (Frontend) or Rust (Backend).
- **No Side Effects**: Isolate side effects to React Effects or API handlers. Use pure functions for business logic.
- **Handling Failure**: Never use `panic!` in Rust or throw exceptions in ReScript. Return `Result` or `Option` types.

### Build & Test Integrity
- **Mandatory Testing**: `npm test` must pass before any commit.
- **Build Verification**: Run `npm run build` after major changes to ensure compilation passes across the entire project.

---

## 2. Automated Workflows (Phase 1-3)

We utilize strict automation to maintain quality. **Do not run these manually if an AI agent is handling the task.**

### Phase 1: Pre-Flight
1. **Context Check**: Read `.agent/current_file_structure.md` before editing.
2. **Standards Review**: Read `/functional-standards.md` for logic and `/docs/DESIGN_SYSTEM.md` for UI.

### Phase 2: Execution
- **Commit Workflow**: Use `./scripts/commit.sh` (Auto-increments version, cleans console logs, updates file maps).
- **Time Machine (Undo)**: Use `./scripts/restore-snapshot.sh <HASH>` to rollback internal development states.

### Phase 3: Push Verification
- **Pre-Push Workflow**: Read `/pre-push-workflow.md`. This script runs backend tests and verifies version consistency.

---

## 3. Testing Standards

### Frontend (ReScript)
- **Unit Tests**: Located in `tests/unit/`.
- **Test Runner**: Managed via `tests/TestRunner.res`.
- **Enforcement**: Commits are blocked if the 100% pass rate is not maintained.

### Backend (Rust)
- **Crate Testing**: Use `cargo test` within the `backend/` directory.
- **Coverage**: Focus on services (Project, Media, Geocoding) and algorithms (Pathfinder).

---

## 4. ReScript Migration Strategy

**Current Logic Status: ~95% Complete**

### Implementation Rules
- **Minimize `Obj.magic`**: Avoid type-casting unless interacting with legacy JS libraries that lack bindings.
- **New Modules**: Follow the standards in `/new-module-standards.md`, emphasizing structured logging and error boundaries.
- **Legacy Components**: Incrementally migrate remaining JS functions into ReScript helper modules.

---

## 5. Metadata & Versioning

### Project Metadata
- **Version Control**: Managed via `./scripts/commit.sh`.
- **Standardized Constants**: Use `VersionData.res` and `Constants.res` for global values.

---
*Last Updated: 2026-01-21*
