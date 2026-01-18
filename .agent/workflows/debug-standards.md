---
description: Debugging and Logging Standards
---

# Debugging and Logging Standards

Follow these standards to ensure consistent logging and observational capabilities across the project.

> 📖 **Full Architecture**: See `docs/LOGGING_ARCHITECTURE.md` for complete details.

---

## Quick Reference

### Log Levels

| Level | When to Use | Console | Backend |
|-------|-------------|---------|---------|
| `trace` | Frame-by-frame, animation ticks | Hidden | No |
| `debug` | Step-by-step function flow | Hidden | Conditional |
| `info` | Major lifecycle events | ✅ Shown | ✅ Sent |
| `warn` | Soft failures, unexpected states | ✅ Shown | ✅ Sent |
| `error` | Critical failures | ✅ Shown | ✅ **Always** |
| `perf` | Performance timing | ✅ Shown | ✅ Sent |

### Configuration (`src/constants.js`)

```javascript
export const DEBUG_ENABLED_DEFAULT = false;   // Console output?
export const DEBUG_LOG_LEVEL = 'info';        // Minimum level
export const DEBUG_MAX_ENTRIES = 500;         // Buffer size
export const PERF_WARN_THRESHOLD = 500;       // ms - warn if slower
export const PERF_INFO_THRESHOLD = 100;       // ms - info if slower
```

---

## 1. Using the Logger (ReScript)

**Never use `Console.log`.** Use `Logger` from `src/utils/Logger.res`:

```rescript
// Basic logging
Logger.debug(~module_="Module", ~message="step", ~data=Some({...}), ())
Logger.info(~module_="Module", ~message="EVENT", ~data=Some({...}), ())
Logger.warn(~module_="Module", ~message="WARNING", ())
Logger.error(~module_="Module", ~message="FAILED", ~data=Some({...}), ())

// Performance timing
let {result, _} = Logger.timed(~module_="Module", ~operation="OP", fn)

// Auto-logged errors
let result = Logger.attempt(~module_="Module", ~operation="OP", fn)
```

---

## 2. Using Debug.js (JavaScript)

```javascript
import { Debug } from '../utils/Debug.js';

Debug.debug('Module', 'Step description', { data });
Debug.info('Module', 'LIFECYCLE_EVENT', { data });
Debug.warn('Module', 'SOFT_FAILURE', { reason });
Debug.error('Module', 'CRITICAL_FAILURE', { error });
Debug.perf('Module', 'OPERATION', durationMs, { data });
```

---

## 3. Standard Log Points

Every module should have:

| Event | Level | Pattern |
|-------|-------|---------|
| Init | `info` | `Logger.initialized(~module_="Name")` |
| Action Start | `info` | `{ACTION}_START` |
| Action Complete | `info` | `{ACTION}_COMPLETE` |
| Error | `error` | `{ACTION}_FAILED` (via Logger.attempt) |
| Warning | `warn` | `{ISSUE}` |
| Debug | `debug` | Descriptive step |
| Frame/Tick | `trace` | High-frequency detail |

---

## 4. Performance Thresholds

Operations are auto-classified:

| Duration | Level | Indicator |
|----------|-------|-----------|
| > 500ms | `warn` | 🐢 Very slow |
| > 100ms | `info` | ⏱️ Slow |
| < 100ms | `debug` | ⚡ Fast |

---

## 5. Progress Bar Visibility

Operations longer than **250ms** must show progress:

```javascript
updateProgress(0, "Phase 1: Starting...", true, "Init")
updateProgress(50, "Phase 2: Processing...", true, "Work")
updateProgress(100, "Done", false)
```

---

## 6. Runtime Debugging

### Browser Console Commands

```javascript
DEBUG.enable()                  // Turn on output
DEBUG.disable()                 // Turn off output
DEBUG.setLevel('trace')         // Maximum verbosity
DEBUG.setLevel('debug')         // Development
DEBUG.setLevel('info')          // Default
DEBUG.enableModule('Navigation')// Filter to module
DEBUG.getLog()                  // Get all entries
DEBUG.downloadLog()             // Export as JSON
DEBUG.getSummary()              // Count by module
```

### Keyboard Shortcut (Dev)

**Ctrl+Shift+D** — Toggle debug mode

---

## 7. Troubleshooting Workflow

1. **Check `logs/error.log`** — Recent critical errors
2. **Enable debug** — `DEBUG.setLevel('debug')` in console
3. **Filter by module** — `DEBUG.enableModule('ModuleName')`
4. **Export logs** — `DEBUG.downloadLog('issue_report')`
5. **Analyze** — Filter by timestamp and module

---

## 8. Hybrid Architecture

| Layer | Responsibility |
|-------|----------------|
| **Frontend (ReScript)** | Catch, enrich, buffer, display, forward |
| **Backend (Rust)** | Persist to disk, process, rotate logs |

### Log Files

| File | Content |
|------|---------|
| `logs/telemetry.log` | All logs (JSON lines) |
| `logs/error.log` | Critical errors (plaintext) |
| `logs/backend.log` | Rust internal logs |

---

## 9. DO NOT

- ❌ Use `console.log` or `Console.log`
- ❌ Leave `trace` logs in production hot paths
- ❌ Commit with `DEBUG_LOG_LEVEL = 'debug'`
- ❌ Push `logs/*.log` files to git
- ❌ Use string concatenation for log messages (use data objects)

## DO

- ✅ Use `Logger` module for all ReScript logging
- ✅ Use `Debug.js` for JavaScript logging
- ✅ Include context data in error logs
- ✅ Use `Logger.attempt` for risky operations
- ✅ Use `Logger.timed` for performance-critical code
- ✅ Follow UPPER_SNAKE_CASE for message names

---

## 10. 🤖 AI Agent Troubleshooting Protocol

When the AI Agent is troubleshooting issues with the User, it **MUST** adhere to the following sequence:

1.  **Forensic First**: Before writing any new code, check existing evidence.
    -   Read `logs/error.log` for backend/critical errors.
    -   Check `src/constants.js` to verify `DEBUG_LOG_LEVEL`.
2.  **No Console.log**: The AI is **FORBIDDEN** from inserting `console.log` statements.
    -   *Correction*: If the AI tempted to write `console.log`, it must write `Logger.debug` or `Logger.info` instead.
3.  **Verify Pipeline**: If logs are missing from files:
    -   Verify `src/utils/Logger.res` is initialized.
    -   Verify the backend is reachable (e.g., via `curl` check or verifying previous successful health checks).
4.  **Structured Debugging**:
    -   Instead of "adding print statements", the AI should "instrument with Telemetry" using `Logger.timed` or `Logger.attempt`.

