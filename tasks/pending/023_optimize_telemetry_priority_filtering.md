# Task: Optimize Telemetry Priority Filtering

## Objective

Optimize telemetry communication between frontend (ReScript) and backend (Rust) to prioritize critical failure messages and errors while reducing unnecessary backend traffic. The main goal is to implement intelligent filtering that ensures critical issues are always transmitted while minimizing bandwidth usage for low-priority telemetry data.

## Acceptance Criteria

- [ ] Implement priority-based filtering in `Logger.res` to classify log entries by criticality
- [ ] Configure backend telemetry endpoint to accept priority metadata
- [ ] Ensure all `error` level logs are **always** transmitted immediately to backend
- [ ] Ensure all `warn` level logs are transmitted to backend
- [ ] Implement conditional transmission for `info` level logs (only significant lifecycle events)
- [ ] Prevent `debug` and `trace` level logs from being sent to backend (console-only)
- [ ] Add batching mechanism for non-critical logs to reduce HTTP request overhead
- [ ] Implement exponential backoff for failed telemetry transmissions
- [ ] Add telemetry queue size limits to prevent memory bloat
- [ ] Update `src/constants.js` with new telemetry configuration constants
- [ ] Verify backend can handle priority-filtered telemetry without data loss
- [ ] Document the new priority filtering system in `docs/ARCHITECTURE.md`

## Technical Notes

### Current State
- All log levels are currently sent to backend indiscriminately
- No batching mechanism exists for telemetry transmission
- Backend may receive excessive low-priority data during normal operation

### Proposed Architecture

**Frontend (Logger.res)**:
1. Add `priority` field to telemetry payload: `Critical | High | Medium | Low`
2. Map log levels to priorities:
   - `error` → `Critical` (immediate transmission)
   - `warn` → `High` (immediate transmission)
   - `info` → `Medium` (batched transmission, 5s interval)
   - `debug`, `trace` → `Low` (console-only, no backend transmission)
3. Implement telemetry queue with priority lanes
4. Add batch transmission for Medium priority logs
5. Add circuit breaker pattern for backend unavailability

**Backend (Rust)**:
1. Update telemetry endpoint to accept priority metadata
2. Implement priority-based log routing (Critical/High → `error.log`, Medium → `telemetry.log`)
3. Add rate limiting per priority level
4. Implement log rotation based on priority and size

**Configuration Constants** (`src/constants.js`):
```javascript
// Telemetry Priority Settings
export const TELEMETRY_BATCH_INTERVAL = 5000;        // ms - batch non-critical logs
export const TELEMETRY_BATCH_SIZE = 50;              // max entries per batch
export const TELEMETRY_QUEUE_MAX_SIZE = 1000;        // max queue entries
export const TELEMETRY_RETRY_MAX_ATTEMPTS = 3;       // retry failed transmissions
export const TELEMETRY_RETRY_BACKOFF_MS = 1000;      // initial backoff delay
export const TELEMETRY_CRITICAL_TIMEOUT = 5000;      // ms - timeout for critical logs
export const TELEMETRY_BATCH_TIMEOUT = 10000;        // ms - timeout for batched logs
```

### Files to Modify
- `src/utils/Logger.res` - Add priority filtering and batching
- `src/utils/Debug.js` - Update to respect priority levels
- `src/constants.js` - Add telemetry configuration
- `src-tauri/src/telemetry.rs` - Update backend endpoint
- `docs/ARCHITECTURE.md` - Document new system
- `.agent/workflows/debug-standards.md` - Update logging standards

### Performance Impact
- **Expected reduction**: 70-90% fewer backend requests during normal operation
- **Critical path**: Zero latency added for error/warn logs
- **Memory overhead**: ~50KB for telemetry queue (configurable)

### Testing Strategy
1. Unit tests for priority classification
2. Integration tests for batching mechanism
3. Load tests to verify backend can handle burst critical logs
4. Failure scenario tests (backend unavailable, network timeout)

## Related Documentation
- `/debug-standards.md` - Current logging standards
- `docs/ARCHITECTURE.md` - System architecture
- `logs/telemetry.log` - Current telemetry output
