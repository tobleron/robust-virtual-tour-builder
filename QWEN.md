# 🚀 PROJECT PROTOCOLS & CONTEXT (v5.0)

## 🧠 CORE BEHAVIOR (SYSTEM 2 THINKING)
1. **Context First**: ALL paths must be relative to root. **ALWAYS READ `MAP.md` and `DATA_FLOW.md` FIRST**.
2. **MAP.md Integrity**: When updating `MAP.md`, ALWAYS use **root-relative paths** (e.g., `[src/Main.res](src/Main.res)`). NEVER use absolute paths or `file:///` URIs.
3. **Commitment Constraint**: NEVER run `commit.sh`, `fast-commit.sh`, or `triple-commit.sh` unless explicitly asked to "save", "checkpoint", or "commit".
4. **Task Protocol**: Before handling any task related concerns, read `tasks/TASKS.md`.
5. **Conditional Context Loading**:
   - **IF** writing `.res` files: Read `.agent/workflows/rescript-standards.md`.
   - **IF** writing `.rs` files: Read `.agent/workflows/rust-standards.md`.
   - **IF** writing Tests: Read `.agent/workflows/testing-standards.md`.
   - **IF** debugging/instrumenting: Read `.agent/workflows/debug-standards.md`.
   - **IF** creating **NEW** modules: Read `.agent/workflows/new-module-standards.md`.

## 🚨 CODING VITALS (PRIORITY 0)
- **ReScript v12 Only**: Use `Option`/`Result` explicitly. NO `unwrap()`, `panic!`, or `console.log`.
- **Schema Validation**: Use `rescript-json-combinators` (module `JsonCombinators`) for all JSON/IO interactions to ensure CSP compliance (no `eval`). Forbid `rescript-schema` and legacy `JSON` module.
- **Logger Module**: Use `Logger.debug/info/error` for all telemetry. High-value events and all `Diagnostic Mode` traces are visible via `./scripts/tail-diagnostics.sh`.
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable`.
- **Zero Warnings**: Production builds MUST have zero compiler warnings.

## 🛠️ WORKFLOW AUTOMATION

### PHASE 0: TROUBLESHOOTING
- **Trigger**: When asked to "troubleshoot", "debug", "fix", or investigate a bug.
- **Action**: Create `tasks/active/T###_troubleshoot_[context].md` immediately (Sequential numbering with project tasks).
- **Mandatory Content**:
  - [ ] **Hypothesis (Ordered Expected Solutions)**: Checkbox list ordered by highest probability first. Each item must be an expected fix path, not just a symptom.
  - [ ] **Activity Log**: Checkbox list of experiments/edits.
  - [ ] **Code Change Ledger**: During troubleshooting, record every code change as it happens (file path + short change summary + revert note) so individual edits can be rolled back surgically.
  - [ ] **Rollback Check**: [ ] (Confirmed CLEAN or REVERTED non-working changes).
  - [ ] **Context Handoff**: 3-sentence summary for the next session if the window fills up.

### PHASE 1: EXECUTION

### PHASE 2: COMMIT & PUSH
- **Explicit Permission**: Only commit when the user provides a message or instruction.
- **Fast Path (Local Snapshot)**: `./scripts/fast-commit.sh "msg"` (Quick, Local, No Tests/Push).
- **Standard Path (Push)**: `./scripts/commit.sh "msg" [branch]` (Build Guard, Commit, & Push. Note: Tests are currently Bypassed/Manual).
- **Triple Path (Deprecated/Explicit Override Only)**: `ALLOW_TRIPLE_COMMIT=1 ./scripts/triple-commit.sh "msg"` (Use only when explicitly requested to sync main/testing/development).
- **Storage Check**: Before committing, audit for unnecessary large files (logs, temp zips, etc.) and ask the user for cleanup permission.
- **Manual Push**: `./scripts/pre-push.sh` is available for manual verification if needed.

---

## 📚 ESSENTIAL CONTEXT

### Project Overview
The **Robust Virtual Tour Builder** is a professional-grade virtual tour creation platform for real estate and immersive space documentation. Built with **ReScript v12** (frontend) and **Rust** (backend), it features:
- Interactive 360° panoramic viewer with dual-panorama crossfade system
- Intelligent hotspot linking with bidirectional navigation
- Automated teaser video generation (WebM/MP4)
- Self-contained HTML export for portable tours
- Production-grade recovery mechanisms (OperationJournal, RecoveryManager, PersistenceLayer)

**Key Technologies:**
- Frontend: ReScript v12 + React 19 + Rsbuild + Tailwind CSS 4.0 + Pannellum
- Backend: Rust (Actix-web) with image processing, FFmpeg encoding, headless Chrome
- Testing: Vitest (unit) + Playwright (E2E)

### Architecture Overview

#### State Management: Centralized Reducer Pattern
```
reducer(state, action)
  ├→ AppFsm.reduce         # Global FSM (app lifecycle)
  ├→ Scene.reduce          # Scene CRUD operations
  ├→ Hotspot.reduce        # Hotspot management
  ├→ Ui.reduce             # UI mode toggles
  ├→ Navigation.reduce     # Navigation FSM
  ├→ Simulation.reduce     # Autopilot simulation
  ├→ Timeline.reduce       # Timeline management
  └→ Project.reduce        # Project-level operations
```

**Key Files:**
- `src/core/State.res` - Application state definition
- `src/core/Actions.res` - Action type definitions
- `src/core/Reducer.res` - Root reducer orchestration
- `src/core/ReducerModules.res` - Domain-specific reducers

#### FSM Architecture
**NavigationFSM** (`src/systems/Navigation/NavigationFSM.res`):
```
IdleFsm → Preloading → Transitioning → Stabilizing → IdleFsm
             ↓ (error)
          ErrorFsm → (recovery) → Preloading
```

**AppFSM** (`src/core/AppFSM.res`):
```
Initializing → Interactive (viewing/editing)
             ↓
        SystemBlocking (loading/uploading/exporting)
```

#### Dual-Panorama Viewer System
- **ViewerPool** maintains two Pannellum instances: `primary-a` and `primary-b`
- Scene loading on inactive viewer, CSS crossfade transition
- **Key Files:** `src/systems/ViewerSystem.res`, `src/systems/ViewerPool.res`, `src/systems/Scene/SceneTransition.res`

#### Recovery System (Three-Layer)
1. **OperationJournal** - Transactional log in IndexedDB
2. **RecoveryManager** - Handler registry for retryable operations
3. **PersistenceLayer** - Debounced autosave (2000ms)

---

## 🚀 ESSENTIAL COMMANDS

### Development
```bash
# Full development setup (all services concurrently)
npm run dev

# Individual services
npm run dev:frontend      # Frontend dev server (Rsbuild, port 3000)
npm run dev:backend       # Rust backend (cargo watch, port 8080)
npm run res:watch         # ReScript compiler (watch mode)
npm run sw:watch          # Service Worker sync (watch mode)
npm run dev:system        # System governor/monitor
```

### Building
```bash
# Full production build
npm run build             # Sync SW → Build ReScript → Rsbuild

# Individual components
npm run res:build         # Compile ReScript to JavaScript
npm run sw:sync           # Sync Service Worker
cd backend && cargo build --release
```

### Testing
```bash
# All tests (ReScript build + frontend + backend)
npm test

# Frontend unit tests (Vitest)
npm run test:frontend
npm run test:watch        # Watch mode
npm run test:ui           # Vitest UI

# E2E tests (Playwright)
npm run test:e2e
npm run test:e2e:ui       # Playwright UI

# Backend tests
cd backend && cargo test

# Single test file
npx vitest tests/unit/NavigationFSM_v.test.bs.js
```

### Code Quality
```bash
# Format ReScript and Rust
npm run format

# Lint (format + compile)
npm run lint

# Individual formatters
npm run rs:fmt            # ReScript format
npm run rust:fmt          # Rust format (cd backend && cargo fmt)
```

---

## 📁 FILE ORGANIZATION

### Important Documentation Files
- **MAP.md** - Semantic codebase map with file descriptions and tags
- **DATA_FLOW.md** - Critical data flows showing module interactions
- **.agent/workflows/** - Detailed coding standards by domain
- **tasks/TASKS.md** - Task workflow procedures

### Key Directories
```
src/
├── core/                 # State, reducers, types, FSMs, JSON parsers
├── systems/              # Business logic (upload, navigation, simulation, teaser, export)
├── components/           # React UI components
├── utils/                # Pure utilities (math, geo, logging, recovery)
├── bindings/             # External library bindings (Pannellum, Browser APIs)
└── i18n/                 # Internationalization

backend/src/
├── api/                  # REST API endpoints
├── services/             # Backend business logic
├── pathfinder/           # Navigation pathfinding algorithms
└── middleware/           # Actix middleware (rate limiting)

tests/
├── unit/                 # Frontend unit tests (Vitest)
└── e2e/                  # End-to-end tests (Playwright)
```

---

## 🎯 COMMON DEVELOPMENT TASKS

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

---

## 🔬 DEVELOPMENT GUIDELINES

### ReScript Patterns

**Pattern Matching (Exhaustive):**
```rescript
switch navigationState {
| IdleFsm => // ...
| Preloading({targetSceneId}) => // ...
| Transitioning({fromSceneId, toSceneId}) => // ...
| Stabilizing({targetSceneId}) => // ...
| ErrorFsm({code, recoveryTarget}) => // ...
}
```

**JSON Parsing (Type-Safe):**
- Use `@glennsl/rescript-json-combinators` for all JSON decoding/encoding
- Decoders: `src/core/JsonParsersDecoders.res`
- Encoders: `src/core/JsonParsersEncoders.res`
- **Forbid:** `rescript-schema` and legacy `JSON` module

**Testing Structure:**
```rescript
open Vitest

describe("NavigationFSM", () => {
  test("transitions from Idle to Preloading", t => {
    let state = IdleFsm
    let event = UserClickedScene({targetSceneId: "scene-1"})
    let nextState = NavigationFSM.reducer(state, event)

    t->expect(nextState)->Expect.toMatchPattern(Preloading(_))
  })
})
```

### Rust Backend

**Structure:**
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
└─ src/pathfinder/                # Navigation pathfinding
```

**Running Backend:**
```bash
cd backend
cargo watch -x run          # Development (auto-reload)
cargo run --release         # Production
cargo test                  # Tests
cargo fmt                   # Format
```

---

## 📊 LOGGING & TELEMETRY

**Logger Priorities:**
```rescript
Logger.debug("message", ~context)     // Development only
Logger.info("message", ~context)      // General info
Logger.warn("message", ~context)      // Warnings
Logger.error("message", ~context)     // Errors
Logger.perf("operation", ~duration)   // Performance tracking
```

**Telemetry:** Logs are batched and sent to backend endpoint for analysis.  
**Diagnostic Mode:** View traces via `./scripts/tail-diagnostics.sh`

---

## 🔐 SECURITY NOTES

- **Input Sanitization:** Filename validation, directory traversal prevention
- **Rate Limiting:** 30 req/sec per IP via `actix-governor`
- **Upload Limits:** 100MB file size cap, MIME type validation
- **CORS:** Configured per environment (restrictive in production)
- **XSS Prevention:** Strict CSP, mandatory `textContent` usage
- **Memory Safety:** Rust backend eliminates buffer overflows

---

## ⚡ PERFORMANCE CONSIDERATIONS

- **Dual-viewer pool** eliminates load time perception
- **Lazy loading** progressive texture loading (512px → 4K)
- **Debounced saves** prevent excessive IndexedDB writes (2000ms)
- **Rust parallelization** uses Rayon for multi-core image processing
- **IndexedDB caching** FFmpeg Core for instant warm-start

**Performance Budgets:**
| Metric | Target | Status |
|--------|--------|--------|
| Initial Bundle (Gzipped) | < 300KB | ✅ ~280KB |
| Project Load (50 scenes) | < 5s | ✅ ~4s |
| Image Processing (4K) | < 1s | ✅ ~500ms |
| UI Responsiveness | 60 FPS | ✅ |

---

## 🏗️ ARCHITECTURAL PATTERNS

1. **Facade Pattern:** Lightweight facades (e.g., `Api.res` → `ApiLogic.res` → specific APIs)
2. **Orchestrator/Logic Split:** UI components orchestrate, logic modules contain pure functions
3. **Anticipatory Loading:** Preload next scenes without transitioning (NavigationFSM)
4. **Event Buffering:** Queue user actions during blocking operations (AppFSM)
5. **Circuit Breaker:** `CircuitBreaker.res` wraps backend calls for resilience
6. **EventBus Pattern:** Decoupled pub/sub for navigation telemetry, UI notifications, processing updates

---

## 🔄 SESSION RECOVERY

On app startup, `RecoveryCheck.res`:
1. Queries `OperationJournal.getInterrupted()` for crashed operations
2. Displays `RecoveryPrompt.res` UI if found
3. User can retry (`RecoveryManager.retry()`) or dismiss
4. On dismiss, marks operation as cancelled

**PersistenceLayer:** Auto-saves project state every 2 seconds (debounced) to IndexedDB.

---

## 📋 KNOWN ISSUES & TECHNICAL DEBT

### Timeline Pollution (CRITICAL)
**Issue:** When links are edited/deleted, old timeline items are not cleaned up.  
**Impact:** Duplicate LinkIDs in Visual Pipeline, teaser generator confusion.  
**Fix Required:** Add timeline cleanup in `handleRemoveHotspot` (`src/core/HotspotHelpers.res`).

### Visited Tracking Loops (HIGH)
**Issue:** Teaser/autoforward tracks visited scenes (by index), not links (by linkId).  
**Impact:** Infinite loops when revisiting scenes through different links.  
**Fix Required:** Change `visitedScenes: array<int>` → `visitedLinkIds: array<string>`.

### Obj.magic Usage (MEDIUM)
**Issue:** 38 instances of unsafe type casting remain.  
**Goal:** Replace with type-safe `rescript-json-combinators`.

---

## 📖 ADDITIONAL RESOURCES

- `README.md` - Full project documentation and feature overview
- `MAP.md` - Semantic codebase map with functionality tags
- `DATA_FLOW.md` - Critical data flow diagrams
- `CHANGELOG.md` - Version history
- `.agent/workflows/` - Detailed coding standards by domain

---

**Last Updated:** February 24, 2026  
**Version:** 4.5.4
