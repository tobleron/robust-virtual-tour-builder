# Observability, Debugging & Error Handling

This unified document defines the standards for how we monitor, debug, and handle failures within the Robust Virtual Tour Builder.

---

## 1. Error Handling Standards (ReScript)

To maintain consistent observability, all engineers must follow the **Standardized Error Extraction Pattern**.

### The Rule
Never use raw pattern matching on exceptions like `| Js.Exn.Error(e) => ...`. Instead, always use `Js.Exn.asJsExn(exn)` to safely distinguish between JavaScript runtime errors and internal ReScript exceptions.

### Why?
Raw `exn` types are opaque in ReScript. Casting them to `Js.Exn.t` is the only reliable way to access the `message` and `stack` properties required for high-quality logging.

### The Standard Snippet
Use this pattern in all `try/catch` blocks and `Promise.catch` handlers:

```rescript
try {
  // ... risky code ...
} catch {
| exn =>
  let (msg, stack) = Logger.getErrorDetails(exn)
  
  Logger.error(
    ~module_="YourModule",
    ~message="OPERATION_FAILED",
    ~data={"error": msg, "stack": stack},
    ()
  )
}
```

*Note: `Logger.getErrorDetails(exn)` is a globally available helper that implements the `asJsExn` casting logic.*

---

## 2. Logging Architecture (Hybrid Design)

The project uses a hybrid design where the frontend enriches logs with UI context, and the backend persists them to disk.

### Responsibility Split
- **Frontend (ReScript)**: Captures navigation states, user interactions, and viewer events. Maintains a 2000-entry ring buffer in memory.
- **Backend (Rust)**: Persists logs to `logs/telemetry.log` (JSON) and `logs/error.log` (Plaintext). Implements log rotation and 7-day retention.

### Log Levels
- `trace`: High-frequency frame/animation ticks.
- `debug`: Step-by-step internal flow and state changes.
- `info`: Major lifecycle events (Initializations, Uploads, Saves).
- `warn`: Soft failures (Missing assets, performance lag).
- `error`: Critical failures (Always forwarded to backend disk).
- `perf`: Timing data (Classified as 🐢 Slow, ⏱️ Moderate, or ⚡ Fast).

---

## 3. Debugging Workflows

### Runtime Console Controls
In development mode, use the `window.DEBUG` object:
- `DEBUG.enable()` / `DEBUG.disable()`: Toggle console output.
- `DEBUG.setLevel('debug')`: Increase verbosity.
- `DEBUG.getLog()`: Access the full in-memory log buffer.

### State Inspection
Inspect application state directly in the console (Dev Mode only):
- `window.store.state`: Current filtered state.
- `window.store.getFullState()`: Raw, read-only state snapshot.

### Production Debugging
If state inspection is required in production:
1. Set `ENABLE_STATE_INSPECTOR=true` in the environment.
2. Rebuild via `npm run build`.
3. Access via `window.store.state`.
4. **Security Warning**: Disable this immediately after debugging.

---

## 4. Simulation & Telemetry

Simulation Mode (Play icon ▶) allows testing of tour navigation logic.

### Key Telemetry Events
1. **JOURNEY_START**: Records initial camera position and momentum.
2. **CROSSFADE_TRIGGER**: Captured when the scene swap begins (standardized at 80% progress).
3. **AUTOFORWARD_CHAIN**: Tracks automated "bridge" navigation sequences.

### Performance Monitoring
Watch for 🐢 icons in the console. These indicate operations taking >500ms (e.g., heavy image processing or complex pathfinding).

---
*Last Updated: 2026-01-18*
