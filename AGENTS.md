# AGENTS.md

This file provides universal guidelines for agents working with code in this repository.

## 🧠 Core Protocols & System 2 Thinking

**Context-First Approach:**
1. **ALWAYS READ FIRST**: Start every task by reading `MAP.md` and `DATA_FLOW.md` for context
2. **MAP.md Integrity**: When updating `MAP.md`, ALWAYS use root-relative paths (e.g., `[src/Main.res](src/Main.res)`). NEVER use absolute paths or `file:///` URIs
3. **Root-Relative Paths**: All file references must be relative to repository root

**Commitment Constraint:**
- NEVER run `commit.sh` or `fast-commit.sh` unless explicitly asked to "save", "checkpoint", or "commit"
- Only commit when the user explicitly provides a message or instruction

**Task Protocol:**
- Before handling any task-related concerns, read `tasks/TASKS.md`
- Follow the exact procedures: Read `TASKS.md` → Move to `active/` → Implement → Verify build → Archive

**Conditional Context Loading:**
- **IF** writing `.res` files: Read `.agent/workflows/rescript-standards.md`
- **IF** writing `.rs` files: Read `.agent/workflows/rust-standards.md`
- **IF** writing Tests: Read `.agent/workflows/testing-standards.md`
- **IF** debugging/instrumenting: Read `.agent/workflows/debug-standards.md`
- **IF** creating **NEW** modules: Read `.agent/workflows/new-module-standards.md`

## 🚨 Coding Vitals (PRIORITY 0)

These are non-negotiable requirements for all code:

1. **ReScript v12 Only**: Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`, or `console.log`
2. **Schema Validation**: Use `@glennsl/rescript-json-combinators` (module `JsonCombinators`) for all JSON/IO interactions to ensure CSP compliance (no `eval`). Forbid `rescript-schema` and legacy `JSON` module
3. **Logger Module**: Use `Logger.debug/info/warn/error` for all telemetry. High-value events and all diagnostic traces are visible via `./scripts/tail-diagnostics.sh`
4. **Immutability**: Maintain functional purity in ReScript; avoid `mutable` keyword
5. **Zero Warnings**: Production builds MUST have zero compiler warnings

## Project Overview

The Robust Virtual Tour Builder is a professional-grade web application for creating interactive 360° virtual tours. Built with **ReScript** (frontend) and **Rust** (backend), it features a sophisticated FSM-based architecture, dual-panorama viewer system, and production-grade recovery mechanisms.

**Key Technologies:**
- Frontend: ReScript v12 + React 19 + Rsbuild + Tailwind CSS 4.0 + Pannellum
- Backend: Rust (Actix-web) with image processing, FFmpeg encoding, and headless Chrome
- Testing: Vitest (unit) + Playwright (E2E)

## Essential Commands

### Development
```bash
# Full development setup (runs all services concurrently)
npm run dev

# Individual services
npm run dev:frontend      # Frontend dev server (Rsbuild)
npm run dev:backend       # Rust backend (cargo watch)
npm run res:watch         # ReScript compiler (watch mode)
npm run sw:watch          # Service Worker sync (watch mode)
```

### Building
```bash
# Full production build
npm run build

# Build components
npm run res:build         # Compile ReScript to JavaScript
npm run sw:sync           # Sync Service Worker
cd backend && cargo build --release
```

### Testing
```bash
# Run all tests (ReScript build + frontend + backend)
npm test

# Frontend unit tests (Vitest)
npm run test:frontend

# Frontend tests in watch mode
npm run test:watch

# Vitest UI
npm run test:ui

# E2E tests (Playwright)
npm run test:e2e
npm run test:e2e:ui       # With Playwright UI

# Backend tests
cd backend && cargo test

# Run a single test file
npx vitest tests/unit/NavigationFSM_v.test.bs.js
```

### Code Quality
```bash
# Format ReScript and Rust
npm run format

# Lint (format + compile)
npm run lint

# ReScript format only
npm run rs:fmt

# Rust format only
npm run rust:fmt
```

### Committing Changes

**PHASE 1: Build**
- For normal requests, skip building (let dev server handle it)

**PHASE 2: Commit & Push**
- **Explicit Permission Required**: Only commit when the user provides a message or instruction ("save", "checkpoint", or "commit")
- **Fast Path (Local Snapshot)**: `./scripts/fast-commit.sh "msg"` - Quick, local-only, no tests/push
- **Standard Path (Push to Branch)**: `./scripts/commit.sh "msg" [branch]` - Build guard, commit, and push. Note: Tests are currently bypassed/manual
- **Triple Path (Full Sync)**: `./scripts/triple-commit.sh "msg"` - Syncs and pushes to main/testing/dev branches
- **Manual Verification**: `./scripts/pre-push.sh` is available for manual pre-push verification if needed

## Architecture Overview

### State Management: Centralized Reducer Pattern

The application uses a **composite reducer pattern** with domain-specific sub-reducers in `src/core/Reducer.res`:

```
reducer(state, action)
  ├→ AppFsm.reduce         # Global FSM (app lifecycle)
  ├→ Scene.reduce          # Scene CRUD operations
  ├→ Hotspot.reduce        # Hotspot management
  ├→ Ui.reduce            # UI mode toggles
  ├→ Navigation.reduce     # Navigation FSM
  ├→ Simulation.reduce     # Autopilot simulation
  ├→ Timeline.reduce       # Timeline management
  └→ Project.reduce        # Project-level operations
```

**Key Points:**
- All state is immutable; reducers return `option<state>`
- Multiple reducers can handle the same action independently
- Complex mutations delegated to `SceneMutations.res`
- State lives in `src/core/State.res`

### FSM Architecture (Finite State Machines)

Two critical FSMs orchestrate application behavior:

#### 1. NavigationFSM (src/systems/Navigation/NavigationFSM.res)
Controls panorama viewer navigation through distinct phases:

```
IdleFsm → Preloading → Transitioning → Stabilizing → IdleFsm
             ↓ (error)
          ErrorFsm → (recovery) → Preloading (with retry)
```

**Features:**
- Anticipatory loading (preload without transitioning)
- Automatic retry on timeout/failure
- Interruption handling (user can change target mid-transition)

#### 2. AppFSM (src/core/AppFSM.res)
Manages global application lifecycle:

```
Initializing → Interactive (viewing/editing modes)
             ↓
        SystemBlocking (loading/uploading/exporting)
```

**Event Buffering:** During blocking operations, user actions are queued in `pendingAction` and executed after unblocking.

### Dual-Panorama Viewer System

The viewer uses a **two-instance pool** for seamless crossfade transitions:

1. **ViewerPool** maintains two Pannellum instances: `primary-a` and `primary-b`
2. **Scene loading** happens on the inactive viewer in the background
3. **Transition** swaps active/inactive roles via CSS opacity changes
4. **Cleanup** destroys old viewer asynchronously

**Result:** Zero-flicker transitions between panoramas.

**Key Files:**
- `src/systems/ViewerSystem.res` - Viewer orchestrator
- `src/systems/ViewerPool.res` - Instance lifecycle management
- `src/systems/Scene/SceneLoader.res` - Scene loading coordination
- `src/systems/Scene/SceneTransition.res` - CSS transition management

### Upload Processing Pipeline

Multi-stage pipeline coordinating frontend and backend:

```
UploadProcessor.res (orchestrator)
  ├─ OperationJournal.startOperation()        # Transaction log
  ├─ Resizer.checkBackendHealth()             # Backend connectivity
  ├─ ImageValidator.validateFiles()           # Client-side validation
  ├─ Fingerprinting + Backend Processing      # Rust backend
  │  ├─ Multi-resolution resize (512px, 4K)
  │  ├─ EXIF extraction
  │  ├─ Quality analysis
  │  └─ Duplicate detection (SHA-256)
  └─ OperationJournal.completeOperation()     # Success marker
```

**Backend API:** Runs on http://localhost:8080 (Rust Actix-web server)

### Recovery System (Three-Layer Architecture)

Production-grade recovery ensures data integrity:

#### Layer 1: OperationJournal (src/utils/OperationJournal.res)
- Transactional log stored in IndexedDB
- Tracks operation status: Pending | InProgress | Completed | Failed | Interrupted
- Auto-cleanup of completed operations

#### Layer 2: RecoveryManager (src/utils/RecoveryManager.res)
- Handler registry for retryable operations
- Wraps recovery logic with telemetry and error handling
- Provides structured recovery UX via EventBus

#### Layer 3: PersistenceLayer (src/utils/PersistenceLayer.res)
- Debounced autosave (2000ms) to IndexedDB
- Lazy session recovery on app startup
- Uses `requestIdleCallback` for non-blocking saves

### Event Communication: EventBus Pattern

`src/systems/EventBus.res` provides decoupled pub/sub for:
- Navigation telemetry (NavStart/NavCompleted/NavProgress)
- UI notifications (toasts, modals)
- Processing updates (upload/export progress)
- Component coordination (hotspot sync, context menus)

**Pattern:** Dispatch includes auto-logging interceptor.

## ReScript Development Guidelines

### Code Organization & Patterns

1. **Functional Purity**:
   - UI components in `src/components/`
   - Business logic in `src/systems/`
   - State definitions in `src/core/State.res`
2. **No Alerts**: Use `EventBus.dispatch(ShowNotification(...))` instead of browser alerts
3. **No Console Logs**: Use `Logger` module for priority-based telemetry

### Working with ReScript

**Compilation:**
- ReScript compiles to JavaScript with `.bs.js` extension (in-source compilation)
- Edit `.res` files, never edit generated `.bs.js` files
- Watch mode: `npm run res:watch`

**Pattern Matching:**
```rescript
// Always handle all cases exhaustively
switch navigationState {
| IdleFsm => // ...
| Preloading({targetSceneId}) => // ...
| Transitioning({fromSceneId, toSceneId}) => // ...
| Stabilizing({targetSceneId}) => // ...
| ErrorFsm({code, recoveryTarget}) => // ...
}
```

**JSON Parsing:**
- Use `@glennsl/rescript-json-combinators` for type-safe JSON decoding/encoding
- Decoders in `src/core/JsonParsersDecoders.res`
- Encoders in `src/core/JsonParsersEncoders.res`

### Testing ReScript Code

**Framework:** Vitest with `rescript-vitest` bindings

**Test Structure:**
```rescript
open Vitest

describe("NavigationFSM", () => {
  test("transitions from Idle to Preloading on UserClickedScene", t => {
    let state = IdleFsm
    let event = UserClickedScene({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    t->expect(nextState)->Expect.toMatchPattern(Preloading(_))
  })
})
```

**Running Tests:**
- Tests must be compiled first: `npm run res:build`
- Run tests: `npm run test:frontend`
- Test files end in `_v.test.res` and compile to `_v.test.bs.js`

## Rust Backend Development

### Backend Structure
```
backend/
├─ src/main.rs                    # Server entry point
├─ src/api/                       # API endpoints
│  ├─ media/                      # Image/video processing
│  ├─ project.rs                  # Project load/save/export
│  └─ geocoding.rs                # Address lookup
├─ src/services/                  # Business logic layer
│  ├─ media/                      # Image processing, EXIF, quality
│  ├─ project/                    # Project validation, packaging
│  └─ geocoding/                  # OSM API, caching
└─ src/pathfinder/                # Navigation pathfinding algorithms
```

### Running Backend
```bash
cd backend

# Development (with auto-reload)
cargo watch -x run

# Production
cargo run --release

# Tests
cargo test

# Format
cargo fmt
```

### Backend Features
- **Image Processing**: Multi-resolution resize (Lanczos3), WebP encoding, EXIF extraction
- **Rate Limiting**: 30 req/sec via `actix-governor`
- **Security**: Filename sanitization, 100MB upload limits
- **Video Encoding**: FFmpeg integration for teaser generation
- **Headless Rendering**: Chrome integration for server-side recording
- **Geocoding**: Reverse geocoding with LRU cache


## Common Development Tasks

**Note: For all tasks, you MUST follow the procedure in `tasks/TASKS.md` (Read `TASKS.md`, move to `active/`, implement, verify build, then archive).**

### Adding a New FSM State

1. Define state variant in FSM module (e.g., `NavigationFSM.res`)
2. Add event type for transition trigger
3. Implement transition logic in `reducer` function
4. Handle new state in UI components (pattern match)
5. Add tests for all transition paths

### Adding a New Reducer Domain

1. Create reducer module in `src/core/` (e.g., `MyFeatureReducer.res`)
2. Define action types in `src/core/Actions.res`
3. Implement `reduce(state, action) => option<state>`
4. Add to pipeline in `src/core/Reducer.res`
5. Update state type in `src/core/State.res` if needed

### Adding a New Scene Operation

1. Add action type to `src/core/Actions.res`
2. Implement mutation logic in `src/core/SceneMutations.res`
3. Handle action in `Scene.reduce()` within `Reducer.res`
4. Add tests in `tests/unit/SceneHelpers_v.test.res`

### Adding Recovery for a New Operation

1. Start operation: `OperationJournal.startOperation("MyOperation", context)`
2. Register handler: `RecoveryManager.registerHandler("MyOperation", entry => { /* retry logic */ })`
3. On completion: `OperationJournal.completeOperation(journalId)`
4. On failure: `OperationJournal.failOperation(journalId, reason)`

### Adding a Backend API Endpoint

1. Define endpoint in `backend/src/api/` (e.g., `media/my_feature.rs`)
2. Add route to `backend/src/api/mod.rs`
3. Implement service logic in `backend/src/services/`
4. Add frontend client in `src/systems/Api/` (e.g., `MediaApi.res`)
5. Call from frontend via `Api.MediaApi.myFeature()`

## File Organization Reference

**Important Documentation Files:**
- **MAP.md** - Semantic codebase map with file descriptions and tags
- **DATA_FLOW.md** - Critical data flows showing how data moves through the system
- **.agent/workflows/** - Detailed coding standards by domain (rescript, rust, testing, debug, new-module)
- **tasks/TASKS.md** - Task workflow procedures

**When starting work:**
1. Read MAP.md to understand file locations and purposes
2. Read DATA_FLOW.md to understand how modules interact in key flows
3. Read relevant .agent/workflows/ file based on task type
4. Check tasks/TASKS.md for task management procedure

**Key Directories:**
- `src/core/` - State, reducers, types, FSMs, JSON parsers
- `src/systems/` - Business logic (upload, navigation, simulation, teaser, export)
- `src/components/` - React UI components
- `src/utils/` - Pure utilities (math, geo, logging, recovery)
- `src/bindings/` - External library bindings (Pannellum, Browser APIs)
- `backend/src/api/` - REST API endpoints
- `backend/src/services/` - Backend business logic
- `tests/unit/` - Frontend unit tests (Vitest)
- `tests/e2e/` - End-to-end tests (Playwright)

## Important Architectural Patterns

### When Modifying State

1. **Never mutate state directly** - always return new immutable objects
2. **Use pattern matching exhaustively** - compiler enforces all cases
3. **Update all relevant reducers** - actions may be handled by multiple domains
4. **Consider FSM semantics** - ensure transitions are valid state machine paths

### When Working with Scenes

1. **Coordinate viewer lifecycle** - use `ViewerSystem.Pool` and `Adapter` interfaces
2. **Never directly manipulate Pannellum** - always go through abstraction layers
3. **Handle both viewer instances** - remember dual-panorama architecture
4. **Test scene transitions** - verify FSM state changes in unit tests

### When Adding Async Operations

1. **Register with OperationJournal** - for transaction logging
2. **Implement recovery handler** - in RecoveryManager
3. **Use EventBus for progress** - dispatch processing updates
4. **Handle errors gracefully** - wrap in try/catch, log to telemetry

### When Working with UI

1. **Use EventBus for cross-component communication** - not prop drilling
2. **Access state via AppContext** - `let {state, dispatch} = useAppContext()`
3. **Dispatch actions, not setState** - centralized reducer pattern
4. **Use Logger for debugging** - not console.log

## Logging and Telemetry

**Logger Priorities:**
```rescript
Logger.debug("message", ~context)     // Development only
Logger.info("message", ~context)      // General info
Logger.warn("message", ~context)      // Warnings
Logger.error("message", ~context)     // Errors
Logger.perf("operation", ~duration)   // Performance tracking
```

**Telemetry:** Logs are batched and sent to backend endpoint for analysis.

## Session Recovery

On app startup, `RecoveryCheck.res` component:
1. Queries `OperationJournal.getInterrupted()` for crashed operations
2. Displays `RecoveryPrompt.res` UI if found
3. User can retry (calls `RecoveryManager.retry()`) or dismiss
4. On dismiss, marks operation as cancelled

**PersistenceLayer:** Auto-saves project state every 2 seconds (debounced) to IndexedDB for session recovery.

## Workflows and Standards

Refer to `.agent/workflows/` for detailed procedures:
- `new-module-standards.md` - Module creation guidelines
- `commit-workflow.md` - Commit message conventions
- `debug-standards.md` - Debugging procedures
- `pre-push-workflow.md` - Pre-push checklist

## Performance Considerations

- **Dual-viewer pool** eliminates load time perception
- **Lazy loading** progressive texture loading (512px → 4K)
- **Debounced saves** prevent excessive IndexedDB writes
- **Rust parallelization** uses Rayon for multi-core image processing
- **IndexedDB caching** FFmpeg Core cached for instant warm-start

## Known Patterns to Follow

1. **Facade Pattern**: Many modules are lightweight facades (e.g., `Api.res` → `ApiLogic.res` → specific APIs)
2. **Orchestrator/Logic Split**: UI components orchestrate, logic modules contain pure functions
3. **Anticipatory Loading**: Preload next scenes in NavigationFSM without transitioning
4. **Event Buffering**: Queue user actions during blocking operations (AppFSM)
5. **Circuit Breaker**: `CircuitBreaker.res` wraps backend calls for resilience

## Version Management

- Version defined in `package.json` (semantic versioning)
- Build number incremented automatically
- Service Worker synced on version bump: `npm run version-sync`
- Version utility: `src/utils/Version.res`

## Security Notes

- Input sanitization on backend (filename validation, directory traversal prevention)
- Rate limiting: 30 req/sec per IP
- Upload limits: 100MB file size cap
- CORS configured per environment
- XSS prevention: strict CSP, mandatory `textContent` usage

## Additional Resources

- `README.md` - Full project documentation and feature overview
- `MAP.md` - Semantic codebase map with functionality tags
