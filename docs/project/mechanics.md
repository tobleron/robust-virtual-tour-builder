# Project Mechanics & Dev Workflow

**Last Updated:** March 19, 2026  
**Version:** 5.3.6

---

## 1. Core Development Pillars

### Type Safety & Functional Principles

- **ReScript/Rust First**: All new logic must be written in ReScript (Frontend) or Rust (Backend)
- **Schema Validation**: Use `@glennsl/rescript-json-combinators` for all JSON decoding (API/File IO) to ensure CSP compliance (avoids `eval()`)
- **No Side Effects**: Isolate side effects to React Effects or API handlers. Use pure functions for business logic
- **Handling Failure**: Never use `panic!` in Rust or throw exceptions in ReScript. Return `Result` or `Option` types
- **Immutability**: Maintain functional purity in ReScript; avoid `mutable` keyword

### Build & Test Integrity

- **Zero Warnings Policy**: Compiler warnings are treated as errors. Project must compile cleanly with zero warnings
- **Mandatory Testing**: `npm test` must pass before any commit
- **Build Verification**: Run `npm run build` after major changes to ensure compilation passes across entire project

## 2. Automated Workflows

### Phase 1: Pre-Flight

1. **Context Check**: Read `MAP.md` and `DATA_FLOW.md` before editing
2. **Standards Review**: 
   - `.agent/workflows/functional-standards.md` for logic patterns
   - `.agent/workflows/rescript-standards.md` for ReScript conventions
   - `.agent/workflows/rust-standards.md` for Rust conventions

### Phase 2: Execution

**Commit Workflow:**
```bash
# Standard commit (build guard, commit, push)
./scripts/commit.sh "msg" [branch]

# Fast commit (local snapshot only, no tests/push)
./scripts/fast-commit.sh "msg"
```

**Version Management:**
```bash
# Sync version across files
npm run version-sync

# Manual version bump
npm version patch|minor|major
```

### Phase 3: Push Verification

**Pre-Push Checklist:**
- [ ] `npm run build` passes
- [ ] `npm test` passes (frontend + backend)
- [ ] No console.log in ReScript code
- [ ] No unwrap() in Rust code
- [ ] Version synced across package.json, ServiceWorker, backend

**Pre-Push Command:**
```bash
./scripts/pre-push.sh  # Manual verification
```

## 3. State Management Architecture

### Centralized Reducer Pattern

```rescript
reducer(state, action)
  ├→ AppFSM.reduce         # Global lifecycle FSM
  ├→ Scene.reduce          # Scene CRUD operations
  ├→ Hotspot.reduce        # Hotspot management
  ├→ Ui.reduce             # UI mode toggles
  ├→ Navigation.reduce     # Navigation state + FSM
  ├→ Simulation.reduce     # Autopilot simulation
  ├→ Timeline.reduce       # Timeline management
  └→ Project.reduce        # Project-level operations
```

**Key Files:**
- `src/core/State.res` - Application state definition
- `src/core/Actions.res` - Action type definitions
- `src/core/Reducer.res` - Root reducer orchestration
- `src/core/ReducerModules.res` - Domain-specific reducers

### AppFSM Lifecycle

```
Initializing → Interactive (viewing/editing)
             ↓
        SystemBlocking (loading/uploading/exporting)
             ↓
        Interactive (with pendingAction queue flushed)
```

**Event Buffering:** During blocking operations, user actions are queued in `pendingAction` and executed after unblocking.

### NavigationFSM States

```
IdleFsm → Preloading → Transitioning → Stabilizing → IdleFsm
             ↓ (error)
          ErrorFsm → (recovery) → Preloading (with retry)
```

**Key Features:**
- Anticipatory loading (preload without transitioning)
- Automatic retry on timeout/failure
- Interruption handling (user can change target mid-transition)

### OperationLifecycle System (v5.3.6)

Unified tracking for all long-running operations:

```rescript
type operationState =
  | Idle
  | Running({operationType: operationType, progress: float})
  | Completed({operationType: operationType})
  | Failed({operationType: operationType, error: string})

type operationType =
  | Navigation
  | Upload
  | Export
  | TeaserRecording
  | ProjectSave
  | ProjectLoad
```

**Integration Points:**
- `src/systems/OperationLifecycle.res` - Main orchestrator
- `src/components/LockFeedback.res` - Progress UI
- `src/systems/Navigation/NavigationSupervisor.res` - Navigation tracking

## 4. Initialization Standards

### Predictable Defaults

All state fields must have sensible, non-empty default values:

```rescript
// ✅ Good
tourName: "Tour Name"
activeIndex: 0

// ❌ Bad
tourName: ""
activeIndex: -1
```

**Why:** Default values guide user intent and allow visibility of placeholder text.

### Clean Session Management

- Session state must be explicitly cleared when creating new projects: `SessionStore.clearState()`
- Cached state should never "bleed" into fresh sessions
- **No Persistence on First Load**: `tourName` and `activeIndex` must NEVER be restored from cache on first load. They should only be set by active user input, image uploads, or project imports

### Placeholder Recognition

All placeholder/unknown names must be registered in `TourLogic.isUnknownName()`:

```rescript
let isUnknownName = name => {
  let n = String.toLowerCase(name)
  n == "" || String.includes(n, "unknown") || n == "untitled" || n == "tour" || n == "tour name"
}
```

### Input Sanitization Strategy

**During User Input (Typing):**
- Allow raw input for natural typing
- No sanitization during typing

**During Export/Save Operations:**
- Sanitize at persistence boundaries
```rescript
String.replaceRegExp(tourName, /[^a-z0-9]/gi, "_")
```

## 5. Recovery System (Three-Layer)

### Layer 1: OperationJournal

Transactional log stored in IndexedDB:

```rescript
type operationStatus =
  | Pending
  | InProgress
  | Completed
  | Failed
  | Interrupted

type journalEntry = {
  id: string,
  operationType: string,
  status: operationStatus,
  context: Js.Json.t,
  startedAt: int,
  completedAt: option<int>
}
```

**Auto-cleanup:** Completed operations automatically purged after 7 days.

### Layer 2: RecoveryManager

Handler registry for retryable operations:

```rescript
RecoveryManager.registerHandler("upload", entry => {
  // Retry logic
})
```

**Integration:**
- Circuit breaker for backend calls
- Structured recovery UX via EventBus
- Progress tracking during recovery

### Layer 3: PersistenceLayer

Debounced autosave (2000ms) to IndexedDB:

```rescript
// Debounced save
PersistenceLayer.debounceSave(state)

// Immediate save (critical operations)
PersistenceLayer.immediateSave(state)
```

**Optimization:** Uses `requestIdleCallback` for non-blocking saves.

### Session Recovery Flow

```
App Startup → RecoveryCheck.mount
                 ├─ Query OperationJournal.getInterrupted()
                 ├─ Display RecoveryPrompt.res if found
                 ├─ User can retry or dismiss
                 └─ Load PersistenceLayer session
```

## 6. Navigation Architecture (v5.3.6)

### NavigationSupervisor Pattern

Structured concurrency for navigation tasks:

```rescript
NavigationSupervisor.createTask(intent)
  ├─ Creates AbortSignal for cancellation
  ├─ Cancels previous navigation task
  ├─ dispatch(UserClickedScene) FSM event
  └─ Calls NavigationController with signal

NavigationController → NavigationFSM
                          ├─ State transitions
                          └─ Error recovery

SceneLoader → ViewerSystem → ViewerPool
                 ├─ Load on inactive viewer
                 ├─ CSS crossfade transition
                 └─ AbortSignal integration
```

**Key Files:**
- `src/systems/Navigation/NavigationSupervisor.res` - Task orchestration
- `src/systems/Navigation/NavigationFSM.res` - State machine
- `src/systems/Navigation/NavigationController.res` - FSM subscriber
- `src/systems/Scene/SceneLoader.res` - Scene loading with abort support

### Dual-Viewer Pool

Two Pannellum instances for seamless transitions:

```
ViewerPool
  ├─ primary-a (active, visible)
  └─ primary-b (inactive, preloading)

Transition Flow:
  1. Load scene on inactive viewer (background)
  2. CSS crossfade (opacity swap)
  3. Swap active/inactive roles
  4. Cleanup old viewer asynchronously
```

**Result:** Zero-flicker transitions between panoramas.

## 7. Portal System (v5.3.6)

### Multi-Tenant Architecture

```
Portal Admin Dashboard
  ├─ Tour Management (create, edit, delete)
  ├─ Recipient Management (assign tours)
  ├─ Access Code Generation (short codes)
  └─ Analytics (view counts)

Portal Customer Gallery
  ├─ Access Code Authentication
  ├─ Tour List with Cover Images
  ├─ Branded Tour Viewer
  └─ Shared Links (email invitations)
```

### Portal State Management

Separate state tree for portal surfaces:

```rescript
type portalState = {
  admin: option<adminSession>,
  customer: option<customerSession>,
  tours: array<tour>,
  assignments: array<assignment>
}
```

**Key Files:**
- `src/site/PortalApp.res` - Portal bootstrap
- `src/site/PortalAppAdminSurface.res` - Admin dashboard
- `src/site/PortalAppCustomerSurface.res` - Customer gallery

## 8. ReScript Migration Status

**Current Logic Coverage: ~95%**

### Migration Guidelines

- **Minimize `Obj.magic`**: Avoid type-casting unless interacting with legacy JS libraries
- **New Modules**: Follow `.agent/workflows/new-module-standards.md`
- **Legacy Components**: Incrementally migrate remaining JS functions into ReScript helper modules

### Current JS Files (Intentional)

```
src/site/PageFramework.js     // Static site routing
src/index.js                  // React DOM entry
src/portal-index.js           // Portal entry
```

All other logic is in ReScript.

## 9. Essential Commands

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

# Performance budget tests
npm run test:e2e:budgets
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

## 10. File Organization

### Frontend (`src/`)

```
src/
├── core/                 # State, reducers, types, FSMs, JSON parsers
├── systems/              # Business logic (108 modules)
│   ├── Navigation/       # Navigation supervisor, FSM, controller
│   ├── Scene/            # Scene loading, transitions
│   ├── Viewer/           # Viewer lifecycle, pool
│   ├── Upload/           # Upload processing, validation
│   ├── Exporter/         # Export packaging, delivery
│   ├── Simulation/       # Autopilot simulation
│   ├── Teaser/           # Teaser recording, rendering
│   └── ProjectManager/   # Save/load persistence
├── components/           # React UI components (70+ modules)
├── utils/                # Pure utilities (logging, recovery, math)
├── bindings/             # External library bindings
├── site/                 # Portal system (Admin + Customer)
└── i18n/                 # Internationalization
```

### Backend (`backend/`)

```
backend/
├── src/
│   ├── main.rs           # Server entry point
│   ├── startup.rs        # Server wiring
│   ├── auth.rs           # JWT middleware
│   ├── middleware.rs     # Rate limiting, CORS
│   ├── api/              # REST API endpoints
│   │   ├── media/        # Image/video processing
│   │   ├── project/      # Project CRUD, import/export
│   │   ├── portal/       # Portal admin + public
│   │   └── geocoding/    # Location services
│   ├── services/         # Business logic layer
│   └── pathfinder/       # Navigation pathfinding
└── Cargo.toml
```

## 11. Related Documents

- **[Visual Pipeline](./visual_pipeline.md)** - Graph-based navigation visualization
- **[Testing Strategy](./testing_strategy.md)** - E2E and unit testing approach
- **[Dev System](./dev_system.md)** - Codebase analyzer governance
- **[Runbook & Audits](./runbook_and_audits.md)** - Performance budgets and code quality
- **[Architecture Overview](../architecture/overview.md)** - System architecture patterns

---

**Document History:**
- March 19, 2026: Updated for v5.3.6 with OperationLifecycle, NavigationSupervisor, and Portal system
