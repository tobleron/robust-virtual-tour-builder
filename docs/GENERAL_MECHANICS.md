# General Mechanics & Standards

This document consolidates the development guidelines, initialization standards, and testing strategies for the Robust Virtual Tour Builder.

---

# Part 1: Development Guidelines & Workflow Manual

This section outlines the protocols, standards, and automated workflows required for contributing to the Robust Virtual Tour Builder.

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
1. **Context Check**: Read `.agent/current_file_structure.md` before editing.
2. **Standards Review**: Read `.agent/workflows/functional-standards.md` for logic and `/docs/PROJECT_SPECS.md` (Design System section) for UI.

### Phase 2: Execution
- **Commit Workflow**: Use `./scripts/commit.sh` (Auto-increments version, cleans console logs, updates file maps).
- **Time Machine (Undo)**: Use `./scripts/restore-snapshot.sh <HASH>` to rollback internal development states.

### Phase 3: Push Verification
- **Pre-Push Workflow**: Read `/pre-push-workflow.md`. This script runs backend tests and verifies version consistency.

## 3. Testing Standards

For a detailed breakdown of our methodology, see **Part 3: Testing Strategy** in this document.

### Frontend (ReScript)
- **Three-Tier Safety Net**: We utilize **Unit Tests** (logic), **Smoke Tests** (boot/render), and **Smart Regression Tests** (bug prevention).
- **Unit Tests**: Located in `tests/unit/`.
- **Test Runner**: Managed via `tests/TestRunner.res` and Vitest.
- **Enforcement**: Commits are blocked if the 100% pass rate is not maintained.

### Backend (Rust)
- **Crate Testing**: Use `cargo test` within the `backend/` directory.
- **Coverage**: Focus on services (Project, Media, Geocoding) and algorithms (Pathfinder).

## 4. ReScript Migration Strategy

**Current Logic Status: ~95% Complete**

### Implementation Rules
- **Minimize `Obj.magic`**: Avoid type-casting unless interacting with legacy JS libraries that lack bindings.
- **New Modules**: Follow the standards in `.agent/workflows/new-module-standards.md`, emphasizing structured logging and error boundaries.
- **Legacy Components**: Incrementally migrate remaining JS functions into ReScript helper modules.

## 5. Metadata & Versioning

### Project Metadata
- **Version Control**: Managed via `./scripts/commit.sh`.
- **Standardized Constants**: Use `VersionData.res` and `Constants.res` for global values.

---

# Part 2: Initialization Standards

**Version**: 1.0  
**Last Updated**: 2026-01-23  
**Status**: Active Standard

## 📋 Overview

This section defines the standardized initialization practices for the Robust Virtual Tour Builder. These standards ensure consistent behavior across application startup, new project creation, and project loading scenarios.

## 🎯 Core Principles

### 1. **Predictable Defaults**
- All state fields must have sensible, non-empty default values
- Default values should be meaningful placeholders that guide user intent
- Avoid empty strings where a placeholder would be more helpful

### 2. **Clean Session Management**
- Session state must be explicitly cleared when creating new projects
- Cached state should never "bleed" into fresh sessions
- State restoration should validate cached values before applying them
- **No Persistence on First Load**: The `tourName` and `activeIndex` must NEVER be restored from cache on the first load of the application. They should only be set by active user input, image uploads, or project imports. This prevents "ghost" names from previous sessions from appearing when no scenes are present.

### 3. **Graceful Fallbacks**
- Loading operations must provide consistent fallback values
- Unknown or invalid data should degrade to standard defaults
- Placeholder detection should be centralized and comprehensive

## 🔧 Implementation Standards

### Default State Values

#### Project Name (`tourName`)
```rescript
// ✅ CORRECT: Meaningful placeholder
tourName: "Tour Name"

// ❌ WRONG: Empty string prevents placeholder visibility
tourName: ""
```

**Rationale**: 
- Provides clear visual feedback in the UI
- Allows placeholder text to show when input is focused
- Enables natural typing experience without forced sanitization
- Recognized as a placeholder by `TourLogic.isUnknownName()`

#### Active Scene Index
```rescript
// ✅ CORRECT: Indicates no active scene
activeIndex: -1

// ❌ WRONG: Could reference invalid scene
activeIndex: 0
```

#### Session ID
```rescript
// ✅ CORRECT: Explicitly optional
sessionId: None

// ❌ WRONG: Empty string suggests a session exists
sessionId: Some("")
```

### Placeholder Recognition

All placeholder/unknown names must be registered in `TourLogic.isUnknownName()`:

```rescript
let isUnknownName = name => {
  let n = String.toLowerCase(name)
  n == "" ||
  String.includes(n, "unknown") ||
  n == "untitled" ||
  n == "imported tour" ||
  n == "tour" ||
  n == "tour name" ||
  RegExp.test(/^tour_\d{6}_\d{4}$/i, name) // Matches Tour_DDMMYY_HHMM pattern
}
```

**Purpose**: Enables intelligent name replacement when meaningful data (e.g., EXIF location) becomes available.

### Session State Management

#### Clearing State on New Project

```rescript
// ✅ CORRECT: Explicit state clearing
SessionStore.clearState()
reload()

// ❌ WRONG: Reload without clearing allows state persistence
reload()
```

**Implementation**:
```rescript
// SessionStore.res
let clearState = () => {
  try {
    removeItem(storageKey)
  } catch {
  | _ => ()
  }
}
```

#### Loading Cached State

```rescript
// ✅ CORRECT: Validate before applying
let loadedState = React.useMemo0(() => {
  switch SessionStore.loadState() {
  | Some(s) => {
      ...initialState,
      tourName: TourLogic.isUnknownName(s.tourName) ? initialState.tourName : s.tourName,
      activeIndex: s.activeIndex == -1 ? initialState.activeIndex : s.activeIndex,
      // ... other validated fields
    }
  | None => initialState
  }
})

// ❌ WRONG: Blindly apply cached state
let loadedState = SessionStore.loadState()->Option.getOr(initialState)
```

### Input Sanitization Strategy

#### During User Input (Typing)
```rescript
// ✅ CORRECT: Allow raw input for natural typing
| SetTourName(name) =>
    Some({...state, tourName: name})

// ❌ WRONG: Aggressive sanitization prevents placeholder visibility
| SetTourName(name) =>
    let sanitized = TourLogic.sanitizeName(name, ~maxLength=100)
    Some({...state, tourName: sanitized})
```

#### During Export/Save Operations
```rescript
// ✅ CORRECT: Sanitize at persistence boundaries
let tourName = if state.tourName == "" {
  "Virtual_Tour"
} else {
  state.tourName
}
let safeName = String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")
```

**Rationale**: 
- Users can clear the input to see the placeholder
- Natural typing experience without forced transformations
- Filesystem safety is enforced only when necessary

### Project Loading Fallbacks

#### From ZIP Files
```rescript
// ✅ CORRECT: Consistent fallback
let tourName = switch Nullable.toOption(pd.tourName) {
| Some(tn) if !TourLogic.isUnknownName(tn) => tn
| _ => "Tour Name"
}

// ❌ WRONG: Inconsistent or unclear fallback
| _ => "Imported Tour"  // Different from initialState
| _ => ""               // Empty string
```

#### From Backend Response
```rescript
// ✅ CORRECT: Validate and fallback
Dict.set(
  loadedProject,
  "tourName",
  Dict.get(pd, "tourName")->Option.getOr(castToJson("Tour Name")),
)
```

## 📁 Critical Files

### State Initialization
- **`src/core/State.res`**: Defines `initialState` with all defaults
- **`src/core/AppContext.res`**: Loads and validates cached session state

### Session Management
- **`src/utils/SessionStore.res`**: Handles localStorage persistence and clearing
- **`src/components/Sidebar.res`**: Implements "New Project" workflow

### Validation & Logic
- **`src/utils/TourLogic.res`**: Centralized placeholder detection and sanitization
- **`src/core/reducers/ProjectReducer.res`**: State mutation logic

### Data Loading
- **`src/core/ReducerHelpers.res`**: Project parsing and scene deserialization
- **`src/systems/ProjectManager.res`**: ZIP loading and backend integration
- **`src/systems/UploadProcessor.res`**: EXIF-based name generation

## ✅ Checklist for New Features

When adding new state fields or initialization logic:

- [ ] Define a meaningful default value in `State.initialState`
- [ ] Add validation logic in `AppContext.Provider` if loading from cache
- [ ] Update `SessionStore.sessionState` type if persisting to localStorage
- [ ] Register placeholder values in `TourLogic.isUnknownName()` if applicable
- [ ] Ensure "New Project" workflow clears relevant cached state
- [ ] Document the initialization behavior in this file

## 🐛 Common Pitfalls

### ❌ Empty String Defaults
**Problem**: Empty strings prevent placeholder text from showing in inputs.
```rescript
// BAD
tourName: ""
```
**Solution**: Use a recognized placeholder value.
```rescript
// GOOD
tourName: "Tour Name"
```

### ❌ Cached State Pollution
**Problem**: Old session data persists into new projects.
```rescript
// BAD
onClick: () => reload()
```
**Solution**: Clear session before reload.
```rescript
// GOOD
onClick: () => {
  SessionStore.clearState()
  reload()
}
```

### ❌ Aggressive Input Sanitization
**Problem**: Users can't clear inputs or see placeholders.
```rescript
// BAD - Sanitizes during typing
| SetTourName(name) =>
    Some({...state, tourName: TourLogic.sanitizeName(name)})
```
**Solution**: Sanitize only at persistence boundaries.
```rescript
// GOOD - Raw input during typing
| SetTourName(name) =>
    Some({...state, tourName: name})

// GOOD - Sanitize during save
let safeName = TourLogic.sanitizeName(state.tourName)
```

### ❌ Inconsistent Fallbacks
**Problem**: Different parts of the codebase use different default values.
```rescript
// BAD
| None => "Imported Tour"  // In one place
| None => "Tour Name"      // In another place
| None => ""               // In yet another place
```
**Solution**: Use `State.initialState.tourName` or a consistent constant.

---

# Part 3: Testing Strategy: Unit, Smoke, and Smart Regression

This document outlines the formalized testing strategy for the Robust Virtual Tour Builder, established during the v4.4.7 stability sprint. This strategy ensures long-term maintainability and prevents bug regression.

## 🏛️ The Three-Tier Strategy

Our testing system is built on three pillars, providing deep logic verification, high-level stability checks, and historical bug protection.

### 1. Unit Tests (Logic Guards)
**Goal:** Verify the mathematical and logical correctness of isolated functions.
*   **Target**: Pure functions, mathematical utilities, and data transformers.
*   **Examples**:
    *   `ColorPalette_v.test.res`: Maps IDs to styling tokens.
    *   `HotspotLine_v.test.res`: Validates complex 3D-to-2D projection math.
    *   `ViewerTypes_v.test.res`: Verifies data structure defaults.
*   **Standard**: Every utility module must have 100% logic coverage.

### 2. Smoke Tests (Boot Guards)
**Goal:** Ensure major UI components can "boot" and render their core elements without crashing.
*   **Target**: Complex React components and Context Providers.
*   **Mechanism**: Uses `ReactDOMClient` to mount components into a virtual JSDOM environment.
*   **Examples**:
    *   `ViewerUI_v.test.res`: Checks if the utility bar and logo render.
    *   `Sidebar_v.test.res`: Verifies the main sidebar branding.
    *   `ModalContext_v.test.res`: Ensures the modal system can open and close.
*   **Standard**: Key "Main" components must have a smoke test to prevent "white-screen" errors.

### 3. Smart Regression Tests (Bug Guards)
**Goal:** Codify past bugs into permanent tests to ensure they never return.
*   **Target**: Logic paths that were previously identified as brittle or buggy.
*   **Mechanism**: Simulate the exact conditions that caused a historical failure.
*   **Example**:
    *   `UploadProcessor_v.test.res`: Specifically tests "100% duplicate upload" to ensure the progress bar no longer hangs (fixing a bug from Jan 2026).
*   **Standard**: Every bug fix MUST be accompanied by a regression test in this category.

## 🛠️ Implementation Standards

### 1. Environmental Setup (JSDOM)
All frontend tests run in a JSDOM environment. Components that rely on browser-only APIs (like `ResizeObserver`) must be polyfilled in a setup file.
*   **Setup File**: `tests/unit/LabelMenu_v.test.setup.jsx` (and similar).
*   **Usage**: Registered in `vitest.config.mjs` under `test.setupFiles`.

### 2. Mocking Strategy
To maintain isolation, we use a tiered mocking approach:
*   **Global Mocks**: Use `.test.setup.jsx` files for cross-cutting dependencies (e.g., Shadcn UI components, Lucide Icons).
*   **Partial Mocks**: Use `vi.mock` with `importOriginal` to override specific functions while keeping the rest of the module real.
*   **Component Mocks**: For integration tests, mock sub-components (like `SceneList` inside `Sidebar`) to focus on the parent's logic.

### 3. ReScript Compilation Workflow
Due to occasional file-locking issues with background watchers, the **Standard Build Workflow** is:
1.  Stop background watchers if compilation hangs.
2.  Run `npm run res:build` (Manual Force Build).
3.  Run `npm run test:frontend`.

## 🚀 How to Verify
To verify the entire safety net, run:
```bash
npm run test:frontend
```
This command executes Vitest against the compiled `.bs.js` files, triggering all Unit, Smoke, and Regression tests in a single pass.

## 📅 Maintenance
*   **New Modules**: Must include a `_v.test.res` file.
*   **Complexity**: If a component is too complex for simple unit tests, implement a **Smoke Test** at minimum.
*   **Mocks**: Keep mocks updated in `tests/unit/*.setup.jsx` to reflect changes in the UI library.
