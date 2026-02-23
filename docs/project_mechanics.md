# Project Mechanics & Dev Workflow

This document consolidates the development guidelines, initialization standards, and testing strategies for the Robust Virtual Tour Builder.

---

## 1. Core Development Pillars

### Type Safety & Functional Principles
- **ReScript/Rust First**: All new logic must be written in ReScript (Frontend) or Rust (Backend).
- **Schema Validation**: Use `rescript-json-combinators` (module `JsonCombinators`) for all JSON decoding (API/File IO) to ensure CSP compliance (avoids `eval()`). Manual `Obj.magic` casting for data parsing is strictly forbidden.
- **No Side Effects**: Isolate side effects to React Effects or API handlers. Use pure functions for business logic.
- **Handling Failure**: Never use `panic!` in Rust or throw exceptions in ReScript. Return `Result` or `Option` types.

### Build & Test Integrity
- **Zero Warnings Policy**: Compiler warnings are treated as errors. The project must compile cleanly with zero warnings.
- **Mandatory Testing**: `npm test` must pass before any commit.
- **Build Verification**: Run `npm run build` after major changes to ensure compilation passes across the entire project.

## 2. Automated Workflows (Phase 1-3)

We utilize strict automation to maintain quality. **Do not run these manually if an AI agent is handling the task.**

### Phase 1: Pre-Flight
1. **Context Check**: Read `MAP.md` before editing.
2. **Standards Review**: Read `.agent/workflows/functional-standards.md` for logic and `/docs/project_specs.md` (Design System section) for UI.

### Phase 2: Execution
- **Commit Workflow**: Use `./scripts/commit.sh` (Auto-increments version and cleans console logs).
- **Time Machine (Undo)**: Use `./scripts/restore-snapshot.sh <HASH>` to rollback internal development states.

### Phase 3: Push Verification
- **Pre-Push Workflow**: Read `/pre-push-workflow.md`. This script runs backend tests and verifies version consistency.

## 3. Initialization Standards

These standards ensure consistent behavior across application startup, new project creation, and project loading scenarios.

### Predictable Defaults
- All state fields must have sensible, non-empty default values (e.g. `tourName: "Tour Name"` instead of `tourName: ""`).
- Default values guide user intent and allow visibility of placeholder text.

### Clean Session Management
- Session state must be explicitly cleared when creating new projects (`SessionStore.clearState()`).
- Cached state should never "bleed" into fresh sessions.
- **No Persistence on First Load**: The `tourName` and `activeIndex` must NEVER be restored from cache on the first load of the application. They should only be set by active user input, image uploads, or project imports.

### Placeholder Recognition
All placeholder/unknown names must be registered in `TourLogic.isUnknownName()`:
```rescript
let isUnknownName = name => {
  let n = String.toLowerCase(name)
  n == "" || String.includes(n, "unknown") || n == "untitled" || n == "tour" || n == "tour name"
}
```

### Input Sanitization Strategy
- **During User Input (Typing)**: Allow raw input for natural typing.
- **During Export/Save Operations**: Sanitize at persistence boundaries (`String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")`).

## 4. ReScript Migration Strategy

**Current Logic Status: ~95% Complete**

- **Minimize `Obj.magic`**: Avoid type-casting unless interacting with legacy JS libraries.
- **New Modules**: Follow the standards in `.agent/workflows/new-module-standards.md`, emphasizing structured logging.
- **Legacy Components**: Incrementally migrate remaining JS functions into ReScript helper modules.
