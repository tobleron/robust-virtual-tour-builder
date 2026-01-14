# Logging System Implementation - Task Overview

## Summary

This document outlines the implementation plan for a comprehensive hybrid logging and debugging system across the ReScript frontend and Rust backend.

## Architecture

```
Frontend (ReScript/JS)          Backend (Rust)
┌────────────────────┐         ┌────────────────────┐
│ Logger.res         │         │ /log-telemetry     │
│ Debug.js           │ ──────▶ │ /log-error         │
│ Ring Buffer (500)  │  HTTP   │ tracing crate      │
└────────────────────┘         └────────────────────┘
         │                              │
         ▼                              ▼
    Browser Console              logs/telemetry.log
    User Notifications           logs/error.log
    Downloadable JSON            logs/backend.log
```

## Task List

### Phase 1: Backend Infrastructure (Priority: High)

| # | Task | Description | Est. Time |
|---|------|-------------|-----------|
| 30 | Backend Endpoints | Add `/log-telemetry` and `/log-error` endpoints | 30 min |
| 31 | Rust Internal Tracing | Add tracing to all Rust handlers | 45 min |

### Phase 2: Core Module Migration (Priority: High)

| # | Task | Description | Est. Time |
|---|------|-------------|-----------|
| 32 | Navigation.res | Migrate navigation logging | 30 min |
| 33 | ViewerLoader.res | Migrate viewer loading logging | 30 min |
| 34 | HotspotManager.res | Migrate hotspot interaction logging | 30 min |
| 35 | SimulationSystem.res | Migrate simulation logging | 45 min |
| 36 | Exporter.res | Migrate export process logging | 30 min |
| 37 | UploadProcessor.res | Migrate upload pipeline logging | 45 min |

### Phase 3: Supporting Module Migration (Priority: Medium)

| # | Task | Description | Est. Time |
|---|------|-------------|-----------|
| 38 | InputSystem.res | Migrate keyboard input logging | 15 min |
| 39 | NavigationRenderer.res | Migrate animation logging | 20 min |
| 40 | VideoEncoder.res | Migrate FFmpeg logging | 20 min |
| 41 | Store.res | Add state change logging | 20 min |
| 42 | TeaserSystem | Migrate teaser modules | 30 min |
| 43 | Sidebar.res | Migrate project management logging | 20 min |

### Phase 4: Polish & Integration (Priority: Medium)

| # | Task | Description | Est. Time |
|---|------|-------------|-----------|
| 44 | Debug Shortcuts | Add keyboard shortcuts for debug toggle | 20 min |
| 45 | Remaining Modules | Catch-all for smaller modules | 45 min |

### Phase 5: Advanced Features (Priority: Low)

| # | Task | Description | Est. Time |
|---|------|-------------|-----------|
| 46 | Log Rotation | Implement automatic log file rotation | 45 min |
| 47 | Integration Tests | Create end-to-end logging tests | 30 min |

## Dependencies

```
Task 30 (Backend Endpoints)
    │
    ├──▶ Task 31 (Rust Tracing)
    │
    └──▶ Tasks 32-43 (Module Migrations) ──▶ Task 45 (Remaining)
                                                    │
                                                    ▼
                                              Task 44 (Shortcuts)
                                                    │
                                                    ▼
                                              Task 46 (Rotation)
                                                    │
                                                    ▼
                                              Task 47 (Tests)
```

## Completed Infrastructure

These components are already in place:

- [x] `src/utils/Logger.res` - ReScript logging module
- [x] `src/utils/Debug.js` - Enhanced with `perf()` method
- [x] `src/constants.js` - Performance thresholds added
- [x] `docs/LOGGING_ARCHITECTURE.md` - Full documentation
- [x] `.agent/workflows/debug-standards.md` - Updated workflow

## Expected Outcomes

After completing all tasks:

1. **Unified Logging**: All modules use consistent Logger API
2. **Automatic Error Capture**: Errors always persist to `logs/error.log`
3. **Performance Tracking**: Slow operations automatically flagged
4. **Easy Troubleshooting**: Set debug level to see full flow
5. **Persistent Storage**: All important logs stored on backend
6. **Self-Managed**: Log rotation prevents disk issues

## Quick Start for AI Agent

To work on a task:

1. Read the task file in `tasks/pending/XX_*.md`
2. Follow the implementation steps
3. Run `npm run res:build` to verify compilation
4. Mark testing checklist items as complete
5. Move file to `tasks/completed/` when done

## Log Level Reference

| Level | Use Case | Console | Backend |
|-------|----------|---------|---------|
| `trace` | Frame-by-frame | Hidden | No |
| `debug` | Step flow | Hidden | Conditional |
| `info` | Lifecycle | Shown | Yes |
| `warn` | Soft failures | Shown | Yes |
| `error` | Critical | Shown | **Always** |
