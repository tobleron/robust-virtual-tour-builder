# Developer Preference: Centralized Logging & Debugging System

**Created:** 2026-01-14  
**Updated:** 2026-01-14

## Summary

The user requested a systematic logging and debugging architecture that leverages pure functional programming principles for easy troubleshooting. The system follows a **hybrid approach**:

1. **Frontend (ReScript)**: First line of defense - catches, enriches, and forwards logs
2. **Backend (Rust)**: Persistent storage - receives logs and writes to disk files

## Key Design Decisions

### Hybrid Architecture

| Layer | Responsibility |
|-------|----------------|
| **Frontend** | Catch errors, enrich with UI context, buffer in memory, show user messages, forward to backend |
| **Backend** | Receive telemetry, persist to disk, process/rotate logs, handle backend-specific errors |

### Why Hybrid?

- **Frontend**: Has immediate UI context (scene, hotspot, user action)
- **Backend**: Has reliable persistence (survives browser crashes)
- Together: Best of both worlds

### Log Levels (Priority Order)

| Level | Code | Use Case | Backend Sent |
|-------|------|----------|--------------|
| `trace` | 0 | Frame-by-frame, animation ticks | No |
| `debug` | 1 | Step-by-step function flow | Conditional |
| `info` | 2 | Major lifecycle events | Yes |
| `warn` | 3 | Soft failures, unexpected states | Yes |
| `error` | 4 | Critical failures | **Always** |
| `perf` | 2 | Performance timing metrics | Yes |

### Automatic Features

- Errors **always** go to both `telemetry.log` and `error.log`
- Performance operations >500ms are auto-logged as warnings
- Performance operations >100ms are auto-logged as info
- All logs buffered in-memory (ring buffer of 500 entries)

### Functional Error Handling Pattern

```rescript
let result = Logger.attempt(~module_="Config", ~operation="PARSE", () => {
  parseJson(raw)
})

switch result {
| Ok(data) => use(data)
| Error(_) => showUserError("Parse failed") // Already logged!
}
```

### Performance Timing Pattern

```rescript
let {result, durationMs} = Logger.timed(~module_="Export", ~operation="COMPRESS", () => {
  compress(data)
})
```

## Files Created/Modified

### Infrastructure (Completed)

| File | Purpose |
|------|---------|
| `docs/LOGGING_ARCHITECTURE.md` | Full architecture documentation |
| `.agent/workflows/debug-standards.md` | Updated workflow |
| `src/utils/Logger.res` | Type-safe ReScript logger module |
| `src/utils/Debug.js` | Added `perf()` and `appendToErrorLog()` |
| `src/constants.js` | Added `PERF_WARN_THRESHOLD`, `PERF_INFO_THRESHOLD` |

### Tasks Created

| Task | Description |
|------|-------------|
| 30 | Backend logging endpoints |
| 31 | Rust internal tracing |
| 32-37 | Core module migrations |
| 38-43 | Supporting module migrations |
| 44 | Debug keyboard shortcuts |
| 45 | Remaining modules |
| 46 | Log rotation |
| 47 | Integration tests |

## Console Commands (Runtime)

```javascript
DEBUG.setLevel('trace')   // Maximum verbosity
DEBUG.setLevel('debug')   // Development detail
DEBUG.setLevel('info')    // Default
DEBUG.enableModule('Navigation')  // Filter to module
DEBUG.downloadLog()       // Export for analysis
```

## Troubleshooting Workflow

1. **Check `logs/error.log`** for recent critical errors
2. **Set `DEBUG.setLevel('debug')`** in console for verbose output
3. **Use `DEBUG.getLogByModule('ModuleName')`** to isolate issues
4. **Export with `DEBUG.downloadLog('issue_report')`** for analysis
