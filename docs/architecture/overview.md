# Architecture Overview

**Last Updated:** March 19, 2026  
**Version:** 5.3.6

---

## 📌 Anchor-Based Positioning Standards

**Objective:** Ensure hotspots and UI overlays remain visually pinned to their panoramic coordinates regardless of the user's zoom level or viewport size.

### Core Principles

1. **3D to 2D Projection:** All screen coordinates are derived from 3D (Yaw/Pitch) values using projection mathematics
2. **Normalized Coordinates:** Hotspot positions stored as normalized Yaw (-180 to 180) and Pitch (-90 to 90)
3. **CSS Transforms:** Overlays use `transform: translate3d(...)` for GPU-accelerated rendering
4. **Reactive Updates:** Hotspot positions recalculate on viewer camera changes via `ViewerFollow` system

### Implementation Reference

- **Projection Logic:** `src/utils/ProjectionMath.res` (now integrated into `src/core/HotspotHelpers.res`)
- **Rendering Components:** 
  - `src/components/HotspotLayer.res` - Main hotspot rendering
  - `src/components/ReactHotspotLayer.res` - React-layer preview markers
  - `src/components/HotspotMenuLayer.res` - Interactive menu overlays

### Best Practices

- ✅ **Use** `requestAnimationFrame` for smooth tracking during camera rotation
- ✅ **Debounce** depth calculations for occlusion culling to preserve FPS
- ✅ **Cache** hotspot positions when viewer is static
- ❌ **Avoid** direct `top/left` pixel manipulation for dynamic positioning
- ❌ **Avoid** synchronous DOM reads during camera movement

---

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Frontend (ReScript + React 19)                 │
├─────────────────────────────────────────────────────────────────┤
│  UI Layer               │  State Management                     │
│  - Sidebar              │  - Centralized Reducer                │
│  - ViewerHUD            │  - AppFSM (Global Lifecycle)          │
│  - VisualPipeline       │  - NavigationFSM                      │
│  - HotspotLayer         │  - Domain Reducers (Scene, Hotspot)   │
│  - LabelMenu            │                                       │
│                         │  Recovery Layer                       │
│  Systems                │  - OperationJournal (IndexedDB)       │
│  - NavigationSupervisor │  - RecoveryManager                    │
│  - ViewerSystem         │  - PersistenceLayer (2s debounce)     │
│  - UploadProcessor      │                                       │
│  - TeaserManager        │  Communication                        │
│  - Exporter             │  - EventBus (Pub/Sub)                 │
│  - ProjectManager       │  - CircuitBreaker                     │
└─────────────────────────────────────────────────────────────────┘
                              │ HTTP/JSON
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Backend (Rust + Actix-web)                     │
├─────────────────────────────────────────────────────────────────┤
│  API Layer              │  Services                             │
│  - Auth Middleware      │  - Media Processing (EXIF, Quality)   │
│  - Rate Limiter         │  - Project (Load/Save/Export)         │
│  - CORS                 │  - Geocoding (OSM Nominatim)          │
│                         │  - Portal (Admin + Customer)          │
│  Endpoints              │                                       │
│  - /api/media/*         │  Infrastructure                       │
│  - /api/project/*       │  - SQLite Database                    │
│  - /api/geocoding/*     │  - File Storage (Local/S3)            │
│  - /api/portal/*        │  - FFmpeg (Video Encoding)            │
│  - /api/health          │  - Headless Chrome (Teaser Capture)   │
└─────────────────────────────────────────────────────────────────┘
```

### Frontend Architecture

#### State Management: Centralized Reducer Pattern

```
reducer(state, action)
  ├→ AppFSM.reduce         # Global lifecycle (Initializing → Interactive → Blocking)
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
- `src/core/ReducerModules.res` - Domain-specific reducer implementations

#### Navigation Architecture (v5.3.6)

**NavigationSupervisor Pattern:**
```
User Intent → NavigationSupervisor
                 ├─ Creates AbortSignal for structured concurrency
                 ├─ Cancels previous navigation task
                 ├─ dispatch(UserClickedScene) FSM event
                 └─ Calls NavigationController

NavigationController → NavigationFSM
                          ├─ IdleFsm → Preloading → Transitioning → Stabilizing → IdleFsm
                          └─ Error recovery with retry logic

SceneLoader → ViewerSystem → ViewerPool (dual-instance)
                 ├─ Load on inactive viewer
                 └─ CSS crossfade transition
```

**Key Files:**
- `src/systems/Navigation/NavigationSupervisor.res` - Task orchestration
- `src/systems/Navigation/NavigationFSM.res` - State machine
- `src/systems/Navigation/NavigationController.res` - FSM subscriber
- `src/systems/Scene/SceneLoader.res` - Scene loading
- `src/systems/ViewerPool.res` - Dual-viewer instance pool

#### Operation Lifecycle Tracking

Unified system for tracking all long-running operations:

```
OperationLifecycle
  ├─ Busy State Detection (blocking vs ambient)
  ├─ Progress Monitoring (0-100%)
  ├─ Visibility Thresholds (when to show UI)
  ├─ LockFeedback Integration (progress indicators)
  └─ Recovery Integration (crash resilience)

Tracked Operations:
  - Navigation (scene transitions)
  - Upload (image processing)
  - Export (ZIP packaging)
  - Teaser Recording (video capture)
  - Project Save/Load
```

**Key Files:**
- `src/systems/OperationLifecycle.res` - Main orchestrator
- `src/systems/OperationLifecycleContext.res` - Operation context
- `src/systems/OperationLifecycleTypes.res` - Type definitions
- `src/components/LockFeedback.res` - Progress UI

#### Recovery System (Three-Layer)

**Layer 1: OperationJournal**
- Transactional log in IndexedDB
- Tracks: Pending | InProgress | Completed | Failed | Interrupted
- Auto-cleanup of completed operations

**Layer 2: RecoveryManager**
- Handler registry for retryable operations
- Circuit breaker integration
- Structured recovery UX via EventBus

**Layer 3: PersistenceLayer**
- Debounced autosave (2000ms) to IndexedDB
- Lazy session recovery on startup
- Uses `requestIdleCallback` for non-blocking saves

**Key Files:**
- `src/utils/OperationJournal.res` - Transaction log
- `src/utils/RecoveryManager.res` - Recovery handlers
- `src/utils/PersistenceLayer.res` - Autosave system
- `src/components/RecoveryCheck.res` - Startup recovery check

### Backend Architecture

#### API Structure

```
backend/src/
├── main.rs                  # Server entry point
├── startup.rs               # Server wiring
├── auth.rs                  # JWT middleware
├── middleware.rs            # Rate limiting, CORS
│
├── api/
│   ├── mod.rs               # Router composition
│   ├── config_routes*.rs    # Route tree builders
│   ├── auth.rs              # Authentication endpoints
│   ├── project.rs           # Project CRUD
│   ├── project_import.rs    # Chunked import
│   ├── media/               # Image/video processing
│   ├── portal/              # Portal admin + public
│   ├── geocoding.rs         # Location services
│   └── health.rs            # Health checks
│
├── services/
│   ├── media/               # Image processing logic
│   ├── project/             # Project operations
│   ├── geocoding/           # OSM integration
│   └── portal.rs            # Portal business logic
│
└── pathfinder/
    ├── mod.rs               # Pathfinding entry
    ├── algorithms.rs        # A* search
    └── graph.rs             # Scene graph
```

#### Portal System (v5.3.6)

Multi-tenant customer gallery system:

```
Portal Admin Dashboard
  ├─ Tour Management (create, edit, delete)
  ├─ Recipient Management (assign tours to customers)
  ├─ Access Code Generation (short codes for sharing)
  └─ Analytics (view counts, engagement)

Portal Customer Gallery
  ├─ Branded Tour Viewer
  ├─ Access Code Authentication
  ├─ Tour List with Cover Images
  └─ Shared Links (email invitations)
```

**Key Files:**
- `backend/src/api/portal.rs` - Portal API façade
- `backend/src/api/portal_admin_routes.rs` - Admin endpoints
- `backend/src/api/portal_public_routes.rs` - Customer endpoints
- `backend/src/services/portal.rs` - Portal business logic
- `src/site/PortalApp.res` - Portal frontend bootstrap

#### Media Processing Pipeline

```
Upload → Multipart Receiver
           ├─ Validation (MIME, size)
           ├─ Fingerprinting (SHA-256)
           ├─ EXIF Extraction
           ├─ Multi-Resolution Resize (512px, 4K)
           ├─ Quality Analysis (histogram, blur)
           ├─ WebP Encoding
           └─ Storage (local disk / S3)
```

**Key Files:**
- `backend/src/api/media/image_multipart.rs` - Upload endpoint
- `backend/src/services/media/analysis_exif.rs` - EXIF extraction
- `backend/src/services/media/resizing.rs` - Multi-resolution
- `backend/src/services/media/webp.rs` - WebP encoding

---

## 🎯 Key Architectural Patterns

### 1. Facade Pattern

Lightweight facades hide complexity:

```rescript
// API Facade
Api.res → ApiLogic.res → SpecificApi.res (MediaApi, ProjectApi, etc.)

// Logger Facade
Logger.res → LoggerLogic.res → LoggerConsole/LoggerTelemetry
```

### 2. Orchestrator/Logic Split

UI components orchestrate, logic modules contain pure functions:

```rescript
// Example: Simulation
Simulation.res (orchestrator, operation lifecycle)
  └─ SimulationLogic.res (pure movement logic)
      └─ SimulationMainLogic.res (next move calculation)
```

### 3. Event Buffering

During blocking operations, user actions are queued:

```rescript
AppFSM.SystemBlocking → pendingAction queue
  → Execute queued actions when Interactive
```

### 4. Structured Concurrency

Navigation tasks use AbortSignal for cancellation:

```rescript
NavigationSupervisor.createTask()
  ├─ Creates AbortSignal
  ├─ Cancels previous task
  └─ Passes signal to SceneLoader
```

### 5. Dual-Viewer Pool

Two Pannellum instances for seamless transitions:

```
ViewerPool
  ├─ primary-a (active)
  └─ primary-b (inactive, preloading)

Transition:
  1. Load scene on inactive viewer
  2. CSS crossfade (opacity swap)
  3. Swap active/inactive roles
  4. Cleanup old viewer asynchronously
```

---

## 📊 Performance Architecture

### Performance Budgets

| Metric | Target | Current |
|---|---|---|
| Initial Bundle (Gzipped) | < 300KB | ~280KB ✅ |
| Project Load (50 scenes) | < 5s | ~4s ✅ |
| Image Processing (4K) | < 1s | ~500ms ✅ |
| Scene Switching p95 | < 1.5s | ~125ms (cache) ✅ |
| UI Responsiveness | 60 FPS | ✅ |

### Optimization Strategies

1. **Lazy Loading:** Only initial scene fully loaded; neighbors preloaded in background
2. **Dual-Viewer Pool:** Eliminates load time perception
3. **Progressive Texture Loading:** 512px → 4K resolution steps
4. **Debounced Saves:** 2000ms debounce prevents excessive IndexedDB writes
5. **Rust Parallelization:** Rayon for multi-core image processing
6. **IndexedDB Caching:** FFmpeg Core cached for instant warm-start
7. **Worker Pool:** OffscreenCanvas workers for image processing

---

## 🔐 Security Architecture

### Input Sanitization
- Filename validation (no directory traversal)
- MIME type validation
- Upload size limits (100MB cap)

### Rate Limiting
- 30 req/sec per IP via `actix-governor`
- Per-endpoint rate limits
- Structured 429 responses with retry-after

### Authentication
- JWT-based authentication
- HttpOnly, Secure, SameSite cookies
- Password hashing with Argon2
- OAuth 2.0 (Google) support

### XSS Prevention
- Strict Content Security Policy
- Mandatory `textContent` usage
- No `dangerouslySetInnerHTML`

---

## 🧪 Testing Architecture

### Test Pyramid

```
        E2E (Playwright)
       /                 \
      /   Integration     \
     /_____________________\
    /                       \
   /    Unit (Vitest)        \
  /___________________________\
```

**Unit Tests:** `tests/unit/` - Vitest + ReScript bindings  
**E2E Tests:** `tests/e2e/` - Playwright  
**Budget Tests:** `tests/e2e/perf-budgets.spec.ts` - Performance regression

### Test Commands

```bash
# All tests
npm test

# Frontend unit tests
npm run test:frontend

# E2E tests
npm run test:e2e

# Performance budget tests
npm run test:e2e:budgets

# Backend tests
cd backend && cargo test
```

---

## 📁 Module Organization

### Frontend (`src/`)

| Directory | Purpose |
|---|---|
| `core/` | State, reducers, types, FSMs, JSON parsers |
| `systems/` | Business logic (Navigation, Upload, Export, Teaser) |
| `components/` | React UI components |
| `utils/` | Pure utilities (logging, recovery, math) |
| `bindings/` | External library bindings (Pannellum, Browser APIs) |
| `site/` | Portal system (Admin + Customer surfaces) |

### Backend (`backend/`)

| Directory | Purpose |
|---|---|
| `api/` | REST API endpoints |
| `services/` | Business logic layer |
| `pathfinder/` | Navigation pathfinding algorithms |
| `middleware/` | Auth, rate limiting, CORS |

---

## 🔗 Related Documents

- **[Simulation Architecture](./simulation.md)** - FSM redesign proposal
- **[Async Processing](./async_processing.md)** - Queue/worker migration ADR
- **[Performance](./performance.md)** - Core Web Vitals and budgets
- **[System Robustness](./robustness.md)** - Circuit breakers and retry patterns
- **[Project Mechanics](../project/mechanics.md)** - State management details

---

**Document History:**
- March 19, 2026: Updated for v5.3.6 with Portal system and OperationLifecycle
